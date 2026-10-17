import os
import sys
import copy
import json
import re
import uuid
import time
import queue
import asyncio
import threading
import traceback
import subprocess
import websockets
import opuslib_next
import numpy as np

from core.utils.util import (
    extract_json_from_string,
    check_vad_update,
    check_asr_update,
    filter_sensitive_info,
)
from typing import Dict, Any
from collections import deque
from core.utils.modules_initialize import (
    initialize_modules,
    initialize_tts,
    initialize_asr,
)
from core.handle.reportHandle import report, enqueue_tool_report
from core.handle.sessionEndHandle import finish_chat_session
from core.utils.guardrails import Guardrail
from core.providers.tts.default import DefaultTTS
from concurrent.futures import ThreadPoolExecutor
from core.utils.dialogue import Message, Dialogue
from core.providers.asr.dto.dto import InterfaceType
from core.handle.textHandle import handleTextMessage
from core.providers.tools.unified_tool_handler import UnifiedToolHandler
from plugins_func.loadplugins import auto_import_modules
from plugins_func.register import Action, ActionResponse, all_function_registry, module_func_map
from core.auth import AuthenticationError
from config.config_loader import get_private_config
from core.db import DeviceRefused, get_database, touch_device
from core.db.usage import UsageScope, attribution_from_conn, bind_attribution, track_stream
from core.providers.tts.dto.dto import ContentType, TTSMessageDTO, SentenceType
from config.logger import setup_logging, build_module_string, create_connection_logger
from core.utils.prompt_manager import PromptManager
from core.utils.voiceprint_provider import VoiceprintProvider
from core.utils.util import get_system_error_response
from core.utils import textUtils


TAG = __name__

auto_import_modules("plugins_func.functions")


class TTSException(RuntimeError):
    pass

# direct_answer virtual tool definition
# Not a real tool but a routing mechanism: turns the binary "call a tool or not" choice into a multiple choice of "which one to call", preventing small models from falsely triggering real tools
DIRECT_ANSWER_TOOL = {
    "type": "function",
    "function": {
        "name": "direct_answer",
        "description": "Use this option to reply directly when the user's request matches none of the other tools. Put the reply content in the response parameter.",
        "parameters": {
            "type": "object",
            "properties": {
                "response": {
                    "type": "string",
                    "description": "The complete content of your reply to the user",
                },
            },
            "required": ["response"],
        },
    },
}


class ConnectionHandler:
    def __init__(
            self,
            config: Dict[str, Any],
            _vad,
            _asr,
            _llm,
            _memory,
            _intent,
            server=None,
    ):
        self.common_config = config
        self.config = copy.deepcopy(config)
        self.session_id = str(uuid.uuid4())
        self.logger = setup_logging()
        self.server = server  # Keep a reference to the server instance

        # Set once the per-device config has been loaded from the database
        self.config_ready_event = asyncio.Event()
        self.device_refused = False  # Unknown device while device.auto_register is off
        self.agent_id = None  # Agent resolved for this device (used for attribution)

        # Always true in this build: config, agents and devices come from SQLite
        self.db_enabled = self.config.get("db_enabled", True)

        self.websocket: websockets.ServerConnection | None = None
        self.headers = None
        self.device_id = None
        self.client_ip = None
        self.prompt = None
        self.welcome_msg = None
        self.max_output_size = 0
        self.chat_history_conf = 0
        # Masks personal data in user text; rebuilt with the name list once the private config is loaded
        self.guardrail = Guardrail.from_config(self.config)
        self.audio_format = "opus"
        self.sample_rate = 24000  # Default sample rate, dynamically updated from the client hello message

        # Client state related
        self.client_abort = False
        self.client_is_speaking = False
        self.client_listen_mode = "auto"
        self.client_aec = False  # Whether server-side AEC is enabled

        # Thread task related
        self.loop = None  # The running event loop is obtained in handle_connection
        self.stop_event = threading.Event()
        self.executor = ThreadPoolExecutor(max_workers=5)

        # Add the report thread pool
        self.report_queue = queue.Queue()
        self.report_thread = None
        # This can be modified in the future to adjust ASR and TTS reporting; both are enabled by default for now
        self.report_asr_enable = self.db_enabled
        self.report_tts_enable = self.db_enabled

        # Dependent components
        self.vad = None
        self.asr = None
        self.tts = None
        self._asr = _asr
        self._vad = _vad
        self.llm = _llm
        self.memory = _memory
        self.intent = _intent

        # Manage voiceprint recognition separately for each connection
        self.voiceprint_provider = None

        # VAD related variables
        self.client_audio_buffer = bytearray()
        self.client_have_voice = False
        self.client_voice_window = deque(maxlen=5)
        self.first_activity_time = 0.0  # Time of the first activity (milliseconds)
        self.last_activity_time = 0.0  # Unified activity timestamp (milliseconds)
        self.vad_last_voice_time = 0.0  # Time the user last spoke (milliseconds)
        self.client_voice_stop = False
        self.last_is_voice = False

        # ASR related variables
        # In real deployments a shared local ASR may be used, so variables must not be exposed to the shared ASR
        # Therefore ASR-related variables are defined here as private variables of the connection
        self.asr_audio = []  # Stores the list of PCM frames, shared by VAD and ASR
        self.asr_audio_queue = queue.Queue()
        self.current_speaker = None  # Stores the current speaker
        self.introduced_speakers = set()  # Speakers already "introduced for the first time"; ensures the name is attached only in the first turn
        self.system_introduced_speakers = set()  # Speakers whose identity was already injected into system; ensures the system identity appears only in the first turn

        # LLM related variables
        self.dialogue = Dialogue()

        # TTS related variables
        self.sentence_id = None
        # Handle TTS responses that return no text
        self.tts_MessageText = ""

        # IoT related variables
        self.iot_descriptors = {}
        self.func_handler = None

        self.cmd_exit = self.config["exit_commands"]

        # Whether to close the connection after the chat ends
        self.close_after_chat = False
        self.load_function_plugin = False
        self.intent_type = "nointent"

        self.timeout_seconds = (
                int(self.config.get("close_connection_no_voice_time", 120)) + 60
        )  # Add 60 seconds on top of the first close timeout for the second-stage close
        self.timeout_task = None

        # {"mcp":true} means the MCP feature is enabled
        self.features = None

        # Mark whether the connection comes from MQTT
        self.conn_from_mqtt_gateway = False

        # Initialize the prompt manager
        self.prompt_manager = PromptManager(self.config, self.logger)

        # Initialize the call state
        self.calling = False
        # Mark whether the current mode is incoming-call answering
        self.incoming_call = None

    async def handle_connection(self, ws: websockets.ServerConnection):
        try:
            # Get the running event loop (must be in an async context)
            self.loop = asyncio.get_running_loop()

            # Get and validate headers
            self.headers = dict(ws.request.headers)
            real_ip = self.headers.get("x-real-ip") or self.headers.get(
                "x-forwarded-for"
            )
            if real_ip:
                self.client_ip = real_ip.split(",")[0].strip()
            else:
                self.client_ip = ws.remote_address[0]
            self.logger.bind(tag=TAG).info(
                f"{self.client_ip} conn - Headers: {self.headers}"
            )

            self.device_id = self.headers.get("device-id", None)

            # Authentication passed, continue processing
            self.websocket = ws

            # Check whether the connection comes from MQTT
            request_path = ws.request.path
            self.conn_from_mqtt_gateway = request_path.endswith("?from=mqtt_gateway")
            if self.conn_from_mqtt_gateway:
                self.logger.bind(tag=TAG).info("Connection from: MQTT gateway")

            # Initialize the activity timestamp
            self.first_activity_time = time.time() * 1000
            self.last_activity_time = time.time() * 1000

            # Start the timeout check task
            self.timeout_task = asyncio.create_task(self._check_timeout())

            # Start the AEC cache cleanup task
            self._aec_cache_cleanup_task = asyncio.create_task(self._check_aec_cache_expiry())

            self.welcome_msg = self.config["xiaozhi"]
            self.welcome_msg["session_id"] = self.session_id

            # Read the sample rate from the config
            self.sample_rate = self.welcome_msg["audio_params"]["sample_rate"]
            self.logger.bind(tag=TAG).info(f"Configured output audio sample rate: {self.sample_rate}")

            # Initialize config and components in the background (never blocks the main loop)
            asyncio.create_task(self._background_initialize())

            try:
                async for message in self.websocket:
                    await self._route_message(message)
            except websockets.exceptions.ConnectionClosed:
                self.logger.bind(tag=TAG).info("Client disconnected")

        except AuthenticationError as e:
            self.logger.bind(tag=TAG).error(f"Authentication failed: {str(e)}")
            return
        except Exception as e:
            stack_trace = traceback.format_exc()
            self.logger.bind(tag=TAG).error(f"Connection error: {str(e)}-{stack_trace}")
            return
        finally:
            try:
                await self._save_and_close(ws)
            except Exception as final_error:
                self.logger.bind(tag=TAG).error(f"Error during final cleanup: {final_error}")
                # Make sure the connection is closed even if saving memory fails
                try:
                    await self.close(ws)
                except Exception as close_error:
                    self.logger.bind(tag=TAG).error(
                        f"Error when forcibly closing the connection: {close_error}"
                    )

    def _drain_report_queue(self, timeout=5.0):
        """Wait (blocking) until the chat records queued so far are handed to the db writer."""
        if self.report_thread is None or not self.report_thread.is_alive():
            return
        deadline = time.time() + timeout
        while self.report_queue.unfinished_tasks > 0 and time.time() < deadline:
            time.sleep(0.05)

    async def _save_and_close(self, ws):
        """Store the title and memory, then close the connection"""
        try:
            if self.device_refused:
                return

            # The last chat records must be queued before the connection resources are released
            await asyncio.to_thread(self._drain_report_queue)

            # Messages of this conversation without the temporary few-shot examples
            messages = [m for m in self.dialogue.dialogue if not m.is_temporary]

            # Daemon thread: close the chat session (title, summary) and save memory
            attribution = self.usage_attribution()

            def end_session_task():
                try:
                    finish_chat_session(self, messages)
                except Exception as e:
                    self.logger.bind(tag=TAG).error(f"Failed to write the session title: {e}")
                if not self.memory:
                    return
                loop = None
                try:
                    # Create a new event loop (to avoid conflicts with the main loop)
                    loop = asyncio.new_event_loop()
                    asyncio.set_event_loop(loop)
                    # The memory LLM call runs in this thread: attribute it to this device / agent / session
                    with bind_attribution(attribution):
                        loop.run_until_complete(
                            self.memory.save_memory(messages, self.session_id)
                        )
                except Exception as e:
                    self.logger.bind(tag=TAG).error(f"Failed to save memory: {e}")
                finally:
                    if loop is not None:
                        try:
                            loop.close()
                        except Exception:
                            pass

            # Start a thread to write them without waiting for completion
            threading.Thread(target=end_session_task, daemon=True).start()
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to start the session end task: {e}")
        finally:
            # Close the connection immediately without waiting for the LLM calls to finish
            try:
                await self.close(ws)
            except Exception as close_error:
                self.logger.bind(tag=TAG).error(
                    f"Failed to close the connection after saving memory: {close_error}"
                )

    async def _route_message(self, message):
        """Message routing"""
        if self.device_refused:
            return
        # Wait for the per-device config; discard the message if it is still not there
        if not self.config_ready_event.is_set():
            try:
                await asyncio.wait_for(self.config_ready_event.wait(), timeout=1)
            except asyncio.TimeoutError:
                return

        if isinstance(message, str):
            await handleTextMessage(self, message)
        elif isinstance(message, bytes):
            if self.vad is None or self.asr is None:
                return

            # Handle audio packets from the MQTT gateway
            if self.conn_from_mqtt_gateway and len(message) >= 16:
                handled = await self._process_mqtt_audio_message(message)
                if handled:
                    return

            # Decode PCM directly at the entry point to avoid repeated decoding by VAD and ASR
            pcm_frame = self._decode_opus_packet(message)
            if pcm_frame:
                self.asr_audio_queue.put(pcm_frame)

    async def _process_mqtt_audio_message(self, message):
        """
        Handle audio messages from the MQTT gateway: parse the 16-byte header, extract the audio data, and apply AEC before enqueueing

        Args:
            message: Audio message containing the header

        Returns:
            bool: Whether the message was handled successfully
        """
        try:
            # Parse the timestamp
            timestamp = int.from_bytes(message[8:12], "big")

            audio_data = message[16:]
            # Decode PCM directly at the entry point
            pcm_frame = self._decode_opus_packet(audio_data)
            if not pcm_frame:
                return True

            # AEC processing: if timestamp>0 and AEC is enabled
            if timestamp > 0 and self.client_aec:
                pcm_frame = self._apply_aec(timestamp, pcm_frame)

            self.asr_audio_queue.put(pcm_frame)
            return True
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to parse WebSocket audio packet: {e}")

        # Handling failed; returning False means processing should continue
        return False

    def _apply_aec(self, timestamp: int, pcm_frame: bytes) -> bytes:
        """Apply AEC processing - combined algorithm: cross-correlation delay estimation + Wiener filtering + spectral subtraction"""
        try:
            if not pcm_frame or len(pcm_frame) == 0:
                return pcm_frame

            if not hasattr(self, "aec_audio_cache") or not self.aec_audio_cache:
                return pcm_frame

            mic_audio = np.frombuffer(pcm_frame, dtype=np.int16).astype(np.float32)
            mic_rms = np.sqrt(np.mean(mic_audio ** 2))

            if mic_rms < 100:
                return pcm_frame

            sorted_timestamps = sorted(self.aec_audio_cache.keys())
            if len(sorted_timestamps) < 2:
                return pcm_frame

            # ========== Match reference frames (log power spectrum matching) ==========
            n = len(mic_audio)

            # Find the closest timestamp as the starting point
            closest_idx = min(range(len(sorted_timestamps)), key=lambda i: abs(sorted_timestamps[i] - timestamp))

            # Precompute the log power spectrum of mic_audio (shared inside the loop to avoid repeated FFT)
            mic_window = np.hanning(n)
            mic_fft = np.fft.rfft(mic_audio * mic_window)
            mic_psd = np.abs(mic_fft) ** 2
            mic_log_psd = 10 * np.log10(mic_psd + 1e-8)
            mic_P_xx = np.dot(mic_log_psd, mic_log_psd)

            # Find the best frame via log power spectrum matching: check 2 frames before and after
            best_corr = -1
            best_ref_idx = closest_idx
            best_ref_rms = 0.0

            for offset in range(-2, 3):  # T-2, T-1, T, T+1, T+2
                test_idx = closest_idx + offset
                if test_idx < 0 or test_idx >= len(sorted_timestamps):
                    continue
                test_ts = sorted_timestamps[test_idx]
                test_ref = np.frombuffer(self.aec_audio_cache[test_ts], dtype=np.int16).astype(np.float32)
                test_ref_rms = np.sqrt(np.mean(test_ref ** 2))
                if test_ref_rms < 50:
                    continue

                # Log power spectrum correlation
                test_window = np.hanning(len(test_ref))
                test_fft = np.fft.rfft(test_ref * test_window)
                test_psd = np.abs(test_fft) ** 2
                test_log_psd = 10 * np.log10(test_psd + 1e-8)
                P_xy = np.dot(mic_log_psd, test_log_psd)
                P_yy = np.dot(test_log_psd, test_log_psd)
                corr = abs(P_xy) / (np.sqrt(mic_P_xx) * np.sqrt(P_yy) + 1e-8)

                if corr > best_corr:
                    best_corr = corr
                    best_ref_idx = test_idx
                    best_ref_rms = test_ref_rms

            best_ts = sorted_timestamps[best_ref_idx]
            best_ref = np.frombuffer(self.aec_audio_cache[best_ts], dtype=np.int16).astype(np.float32)
            ref_rms = best_ref_rms

            if ref_rms < 50:
                return pcm_frame

            # Align the reference signal (truncate to the same length)
            aligned_ref = best_ref[:n]
            if len(aligned_ref) < n:
                aligned_ref = np.pad(aligned_ref, (0, n - len(aligned_ref)))

            # ========== Frequency-domain AEC processing (spectral subtraction) ==========
            # Time-domain signals suffer phase distortion after the acoustic path, giving low time-domain correlation with an indeterminate sign of P_xy
            # The frequency-domain magnitude spectrum is unaffected by phase; log power spectrum correlation stays stable at 0.97+
            # Formula: result_mag = max(|mic_fft| - |ref_fft| * scale * coef, 0)

            mic_mag = np.abs(mic_fft)
            mic_phase = np.angle(mic_fft)
            ref_fft = np.fft.rfft(aligned_ref * np.hanning(n))
            ref_mag = np.abs(ref_fft)

            # Compute the echo ratio scale in the frequency domain
            scale = np.sum(mic_mag * ref_mag) / (np.dot(ref_mag, ref_mag) + 1e-8)

            # Adaptive coefficient: dynamically adjusted based on scale and coh
            # Large scale (strong echo) -> large coef; high coh (accurate match) -> large coef
            raw_coef = 1.0 + scale * 3 + (best_corr - 0.97) * 30
            coef = max(0.5, min(3.0, raw_coef))

            # Spectral subtraction (over-subtraction + half-wave rectification)
            echo_mag = ref_mag * scale * coef
            result_mag = np.maximum(mic_mag - echo_mag * 1.5, mic_mag * 0.1)

            # Reconstruct the signal while keeping the phase
            result_fft = result_mag * np.exp(1j * mic_phase)
            output = np.fft.irfft(result_fft, n)

            # When confident it is pure echo, suppress further to ensure VAD cannot detect it
            if best_corr >= 0.97 and ref_rms > 500:
                output = output * 0.3

            # Post-processing: limiting
            output = np.clip(output, -32768, 32767)

            # Convert to bytes
            result = output.astype(np.int16).tobytes()

            return result

        except Exception as e:
            self.logger.bind(tag=TAG).warning(f"[AEC] Processing failed: {e}")
            return pcm_frame

    def _decode_opus_packet(self, opus_packet: bytes) -> bytes:
        """
        Decode an Opus packet into PCM data

        Args:
            opus_packet: Opus-encoded audio data

        Returns:
            bytes: Decoded PCM data; None on failure
        """
        try:
            if not opus_packet or len(opus_packet) == 0:
                return None

            self._init_connection_state(self)
            pcm_frame = self._connection_opus_decoder.decode(opus_packet, 960)
            return pcm_frame
        except Exception as e:
            self.logger.bind(tag=TAG).debug(f"Opus decoding failed: {e}")
            return None

    def _init_connection_state(self, conn):
        """Initialize an independent Opus decoder for the connection"""
        if not hasattr(conn, "_connection_opus_decoder"):
            conn._connection_opus_decoder = opuslib_next.Decoder(16000, 1)

    async def handle_restart(self, message):
        """Handle a server restart request"""
        try:

            self.logger.bind(tag=TAG).info("Received server restart command, preparing to execute...")

            # Send the confirmation response
            await self.websocket.send(
                json.dumps(
                    {
                        "type": "server",
                        "status": "success",
                        "message": "Server restarting...",
                        "content": {"action": "restart"},
                    }
                )
            )

            # Perform the restart asynchronously
            def restart_server():
                """Method that actually performs the restart"""
                time.sleep(1)
                self.logger.bind(tag=TAG).info("Executing server restart...")
                subprocess.Popen(
                    [sys.executable, "app.py"],
                    stdin=sys.stdin,
                    stdout=sys.stdout,
                    stderr=sys.stderr,
                    start_new_session=True,
                )
                os._exit(0)

            # Use a thread to perform the restart to avoid blocking the event loop
            threading.Thread(target=restart_server, daemon=True).start()

        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Restart failed: {str(e)}")
            await self.websocket.send(
                json.dumps(
                    {
                        "type": "server",
                        "status": "error",
                        "message": f"Restart failed: {str(e)}",
                        "content": {"action": "restart"},
                    }
                )
            )

    def _initialize_components(self):
        try:
            if self.tts is None:
                self.tts = self._initialize_tts()
            # Open the speech synthesis channel
            asyncio.run_coroutine_threadsafe(
                self.tts.open_audio_channels(self), self.loop
            )
            self.selected_module_str = build_module_string(
                self.config.get("selected_module", {})
            )
            self.logger = create_connection_logger(self.selected_module_str)

            """Initialize components"""
            if self.config.get("prompt") is not None:
                user_prompt = self.config["prompt"]
                # Initialize with the fast prompt
                prompt = self.prompt_manager.get_quick_prompt(user_prompt)
                self.change_system_prompt(prompt)
                self.logger.bind(tag=TAG).info(
                    f"Fast component initialization: prompt succeeded {prompt[:50]}..."
                )

            """Initialize local components"""
            if self.vad is None:
                self.vad = self._vad
            if self.asr is None:
                self.asr = self._initialize_asr()

            # Initialize voiceprint recognition
            self._initialize_voiceprint()
            # Open the speech recognition channel
            asyncio.run_coroutine_threadsafe(
                self.asr.open_audio_channels(self), self.loop
            )

            """Load memory"""
            self._initialize_memory()
            """Load intent recognition"""
            self._initialize_intent()
            """Initialize the report thread"""
            self._init_report_threads()
            """Update the system prompt"""
            self._init_prompt_enhancement()
            """Inject tool-call few-shot examples (function_call mode only)"""
            self._inject_tool_call_fewshot()

        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to instantiate components: {e}")

    def _init_prompt_enhancement(self):

        # Update context information
        self.prompt_manager.update_context_info(self, self.client_ip)
        enhanced_prompt = self.prompt_manager.build_enhanced_prompt(
            self.config["prompt"],
            self.device_id,
            self.client_ip,
            emoji_enabled=(self.features or {}).get("emoji", True),
        )
        if enhanced_prompt:
            self.change_system_prompt(enhanced_prompt)
            self.logger.bind(tag=TAG).debug("System prompt enhanced and updated")

    def _inject_tool_call_fewshot(self):
        """Inject tool-call few-shot examples into the dialogue history.
        Structure: positive samples (tool-call examples) go before the dynamic system message so they can hit the prefix cache;
        negative samples (direct-answer examples) go after the dynamic system message, right next to the real user message,
        ensuring that the last pattern the model sees before handling the user message is the "do not call a tool" behavior.
        """
        if self.intent_type != "function_call":
            return
        if not hasattr(self, "func_handler") or self.func_handler is None:
            return

        tools = self.func_handler.get_functions()
        if not tools:
            return

        tool_names = {t.get("function", {}).get("name") for t in tools}

        # === few-shot examples (is_temporary) ===
        # Demonstrates direct_answer carrying the response parameter, completing the reply in one call

        # Example 1: direct_answer (reply content goes in the response parameter, no recursion needed)
        da_tc_id = "fewshot_da_001"
        self.dialogue.put(Message(role="user", content="Tell me a story", is_temporary=True))
        self.dialogue.put(Message(
            role="assistant",
            tool_calls=[{
                "id": da_tc_id,
                "function": {"arguments": '{"response": "Sure! What kind of story would you like? A fairy tale, an adventure, or a funny one? Pick one and I will start telling it~"}', "name": "direct_answer"},
                "type": "function", "index": 0,
            }],
            is_temporary=True,
        ))
        self.dialogue.put(Message(
            role="tool", tool_call_id=da_tc_id,
            content="Replied directly", is_temporary=True,
        ))

        # Example 2: real tool call (handle_exit_intent)
        if "handle_exit_intent" in tool_names:
            tc_id = "fewshot_exit_001"
            self.dialogue.put(Message(role="user", content="Bye-bye", is_temporary=True))
            self.dialogue.put(Message(
                role="assistant",
                tool_calls=[{
                    "id": tc_id,
                    "function": {"arguments": '{"say_goodbye": "Goodbye, talk to you next time~"}', "name": "handle_exit_intent"},
                    "type": "function", "index": 0,
                }],
                is_temporary=True,
            ))
            self.dialogue.put(Message(
                role="tool", tool_call_id=tc_id,
                content="Exit intent handled", is_temporary=True,
            ))
            self.dialogue.put(Message(
                role="assistant", content="Goodbye, talk to you next time~", is_temporary=True,
            ))

        self.logger.bind(tag=TAG).debug("Tool-call few-shot examples injected")

    def _init_report_threads(self):
        """Initialize the ASR and TTS report threads"""
        if not self.db_enabled:
            return
        if self.chat_history_conf == 0:
            return
        if self.report_thread is None or not self.report_thread.is_alive():
            self.report_thread = threading.Thread(
                target=self._report_worker, daemon=True
            )
            self.report_thread.start()
            self.logger.bind(tag=TAG).info("TTS report thread started")

    def _initialize_tts(self):
        """Initialize TTS"""
        tts = initialize_tts(self.config)

        if tts is None:
            tts = DefaultTTS(self.config, delete_audio_file=True)

        return tts

    def _initialize_asr(self):
        """Initialize ASR"""
        if (
                self._asr is not None
                and hasattr(self._asr, "interface_type")
                and self._asr.interface_type == InterfaceType.LOCAL
        ):
            # If the shared ASR is a local service, return directly
            # because a single local ASR instance can be shared by multiple connections
            asr = self._asr
        else:
            # If the shared ASR is a remote service, initialize a new instance
            # because a remote ASR involves a websocket connection and a receiving thread, each connection needs its own instance
            asr = initialize_asr(self.config)

        return asr

    def _initialize_voiceprint(self):
        """Initialize voiceprint recognition for the current connection"""
        try:
            voiceprint_config = self.config.get("voiceprint", {})
            if voiceprint_config:
                voiceprint_provider = VoiceprintProvider(voiceprint_config)
                if voiceprint_provider is not None and voiceprint_provider.enabled:
                    self.voiceprint_provider = voiceprint_provider
                    self.logger.bind(tag=TAG).info("Voiceprint recognition was dynamically enabled at connection time")
                else:
                    self.logger.bind(tag=TAG).warning("Voiceprint recognition is enabled but the config is incomplete")
            else:
                self.logger.bind(tag=TAG).info("Voiceprint recognition is not enabled")
        except Exception as e:
            self.logger.bind(tag=TAG).warning(f"Voiceprint recognition initialization failed: {str(e)}")

    async def _background_initialize(self):
        """Initialize config and components in the background (never blocks the main loop)"""
        try:
            # Asynchronously get the differentiated config
            if not await self._initialize_private_config_async():
                return  # device refused: nothing to initialize
            # Initialize components in the thread pool
            self.executor.submit(self._initialize_components)
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Background initialization failed: {e}")

    async def _refuse_device(self):
        """Tell the device it is not registered, then close the WebSocket."""
        self.device_refused = True
        try:
            await self.websocket.send(
                json.dumps(
                    {
                        "type": "server",
                        "status": "error",
                        "message": "Device is not registered on this server",
                        "content": {"action": "device_refused"},
                    }
                )
            )
        except Exception as e:
            self.logger.bind(tag=TAG).debug(f"Could not send the refusal message: {e}")
        try:
            await self.websocket.close(code=1008, reason="device not registered")
        except Exception as e:
            self.logger.bind(tag=TAG).debug(f"Error closing the refused connection: {e}")

    async def _initialize_private_config_async(self) -> bool:
        """Load the differentiated (per-device) config from the database, without blocking the loop.

        Returns False when the device was refused (unknown device while device.auto_register is
        off); the connection is then closed with a message and nothing else is initialized.
        """
        if not self.db_enabled:
            self.config_ready_event.set()
            return True
        try:
            begin_time = time.time()
            private_config = await get_private_config(
                self.config, self.headers.get("device-id")
            )
            self.agent_id = private_config.get("agent_id")
            self.logger.bind(tag=TAG).info(
                f"{time.time() - begin_time} seconds, differentiated config loaded from the database: {json.dumps(filter_sensitive_info({k: v for k, v in private_config.items() if k != "guardrail_names"}), ensure_ascii=False)}"
            )
            # Remember the connection time (through the writer thread, fire and forget)
            touch_device(get_database(), self.headers.get("device-id"))
        except DeviceRefused as e:
            self.logger.bind(tag=TAG).warning(f"Device refused: {e}")
            await self._refuse_device()
            return False
        except Exception as e:
            # Degrade to the default agent's config instead of dropping the device
            self.logger.bind(tag=TAG).error(f"Failed to load the differentiated config: {e}")
            private_config = {}
        self.config_ready_event.set()

        # Guardrail settings and names are read from the database for every connection
        if private_config.get("guardrails") is not None:
            self.config["guardrails"] = private_config["guardrails"]
        self.guardrail = Guardrail.from_config(self.config, private_config.get("guardrail_names"))

        init_llm, init_tts, init_memory, init_intent = (
            False,
            False,
            False,
            False,
        )

        init_vad = check_vad_update(self.common_config, private_config)
        init_asr = check_asr_update(self.common_config, private_config)

        if init_vad:
            self.config["VAD"] = private_config["VAD"]
            self.config["selected_module"]["VAD"] = private_config["selected_module"][
                "VAD"
            ]
        if init_asr:
            self.config["ASR"] = private_config["ASR"]
            self.config["selected_module"]["ASR"] = private_config["selected_module"][
                "ASR"
            ]
        if private_config.get("TTS", None) is not None:
            init_tts = True
            self.config["TTS"] = private_config["TTS"]
            self.config["selected_module"]["TTS"] = private_config["selected_module"][
                "TTS"
            ]
        if private_config.get("LLM", None) is not None:
            init_llm = True
            self.config["LLM"] = private_config["LLM"]
            self.config["selected_module"]["LLM"] = private_config["selected_module"][
                "LLM"
            ]
        if private_config.get("Memory", None) is not None:
            init_memory = True
            self.config["Memory"] = private_config["Memory"]
            self.config["selected_module"]["Memory"] = private_config[
                "selected_module"
            ]["Memory"]
        if private_config.get("Intent", None) is not None:
            init_intent = True
            self.config["Intent"] = private_config["Intent"]
            model_intent = private_config.get("selected_module", {}).get("Intent", {})
            self.config["selected_module"]["Intent"] = model_intent
            # Load the plugin config
            if model_intent != "Intent_nointent":
                plugin_from_server = private_config.get("plugins") or {}
                # Per-agent plugin parameters may be JSON strings or dicts
                plugin_from_server = {
                    plugin: json.loads(config_val) if isinstance(config_val, str) else config_val
                    for plugin, config_val in plugin_from_server.items()
                }
                if plugin_from_server:
                    # Copy the module-level plugin config to each concrete function name,
                    # making it easy to look up description, news_sources and other config per function later
                    for module_name, func_names in module_func_map.items():
                        if module_name in plugin_from_server:
                            module_config = plugin_from_server[module_name]
                            for func_name in func_names:
                                if func_name not in plugin_from_server:
                                    plugin_from_server[func_name] = module_config
                    # Per-agent parameters override the global `plugins.*` settings
                    merged_plugins = copy.deepcopy(self.config.get("plugins") or {})
                    merged_plugins.update(plugin_from_server)
                    self.config["plugins"] = merged_plugins
                    # Expand module-level plugin names into concrete function names
                    expanded_functions = []
                    for plugin_key in plugin_from_server.keys():
                        if plugin_key in all_function_registry:
                            expanded_functions.append(plugin_key)
                        elif plugin_key in module_func_map:
                            expanded_functions.extend(module_func_map[plugin_key])
                        else:
                            expanded_functions.append(plugin_key)
                    self.config["Intent"][self.config["selected_module"]["Intent"]][
                        "functions"
                    ] = expanded_functions
                # With no per-agent plugin entry the Intent model's own `functions` list applies.
                # Nothing reaches the LLM unless tools.server_plugins_enabled is true.
        if private_config.get("prompt", None) is not None:
            self.config["prompt"] = private_config["prompt"]
        if private_config.get("summaryMemory", None) is not None:
            self.config["summaryMemory"] = private_config["summaryMemory"]
        if private_config.get("device_max_output_size", None) is not None:
            self.max_output_size = int(private_config["device_max_output_size"])
        if private_config.get("chat_history_conf", None) is not None:
            self.chat_history_conf = int(private_config["chat_history_conf"])
        if private_config.get("mcp_endpoint", None) is not None:
            self.config["mcp_endpoint"] = private_config["mcp_endpoint"]
        if private_config.get("context_providers", None) is not None:
            self.config["context_providers"] = private_config["context_providers"]

        # Inject replacement words into the TTS module config
        if private_config.get("correct_words", None) is not None:
            select_tts_module = self.config["selected_module"]["TTS"]
            self.config["TTS"][select_tts_module]["correct_words"] = private_config[
                "correct_words"
            ]

        # Use run_in_executor to run initialize_modules in the thread pool, avoiding blocking the main loop
        try:
            modules = await self.loop.run_in_executor(
                None,  # Use the default thread pool
                initialize_modules,
                self.logger,
                private_config,
                init_vad,
                init_asr,
                init_llm,
                init_tts,
                init_memory,
                init_intent,
            )
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to initialize components: {e}")
            modules = {}
        if modules.get("tts", None) is not None:
            self.tts = modules["tts"]
        if modules.get("vad", None) is not None:
            self.vad = modules["vad"]
        if modules.get("asr", None) is not None:
            self.asr = modules["asr"]
        if modules.get("llm", None) is not None:
            self.llm = modules["llm"]
            if hasattr(self.llm, "bind_connection"):
                self.llm.bind_connection(device_id=self.device_id)
        if modules.get("intent", None) is not None:
            self.intent = modules["intent"]
        if modules.get("memory", None) is not None:
            self.memory = modules["memory"]
        return True

    def _initialize_memory(self):
        if self.memory is None:
            return
        """Initialize the memory module"""
        self.memory.init_memory(
            role_id=self.device_id,
            llm=self.llm,
            summary_memory=self.config.get("summaryMemory", None),
        )

        # Get the memory summary config
        memory_config = self.config["Memory"]
        memory_type = self.config["Memory"][self.config["selected_module"]["Memory"]][
            "type"
        ]
        # If nomen or mem_report_only is used, return directly
        if memory_type == "nomem" or memory_type == "mem_report_only":
            return
        # Use mem_local_short mode
        elif memory_type == "mem_local_short":
            memory_llm_name = memory_config[self.config["selected_module"]["Memory"]][
                "llm"
            ]
            if memory_llm_name and memory_llm_name in self.config["LLM"]:
                # If a dedicated LLM is configured, create an independent LLM instance
                from core.utils import llm as llm_utils

                memory_llm_config = self.config["LLM"][memory_llm_name]
                memory_llm_type = memory_llm_config.get("type", memory_llm_name)
                memory_llm = llm_utils.create_instance(
                    memory_llm_type, memory_llm_config
                )
                self.logger.bind(tag=TAG).info(
                    f"Created a dedicated LLM for memory summary: {memory_llm_name}, type: {memory_llm_type}"
                )
                self.memory.set_llm(memory_llm)
            else:
                # Otherwise use the main LLM
                self.memory.set_llm(self.llm)
                self.logger.bind(tag=TAG).info("Using the main LLM as the intent recognition model")

    def _initialize_intent(self):
        if self.intent is None:
            return
        self.intent_type = self.config["Intent"][
            self.config["selected_module"]["Intent"]
        ]["type"]
        if self.intent_type == "function_call" or self.intent_type == "intent_llm":
            self.load_function_plugin = True
        """Initialize the intent recognition module"""
        # Get the intent recognition config
        intent_config = self.config["Intent"]
        intent_type = self.config["Intent"][self.config["selected_module"]["Intent"]][
            "type"
        ]

        # If nointent is used, return directly
        if intent_type == "nointent":
            return
        # Use intent_llm mode
        elif intent_type == "intent_llm":
            intent_llm_name = intent_config[self.config["selected_module"]["Intent"]][
                "llm"
            ]

            if intent_llm_name and intent_llm_name in self.config["LLM"]:
                # If a dedicated LLM is configured, create an independent LLM instance
                from core.utils import llm as llm_utils

                intent_llm_config = self.config["LLM"][intent_llm_name]
                intent_llm_type = intent_llm_config.get("type", intent_llm_name)
                intent_llm = llm_utils.create_instance(
                    intent_llm_type, intent_llm_config
                )
                self.logger.bind(tag=TAG).info(
                    f"Created a dedicated LLM for intent recognition: {intent_llm_name}, type: {intent_llm_type}"
                )
                self.intent.set_llm(intent_llm)
            else:
                # Otherwise use the main LLM
                self.intent.set_llm(self.llm)
                self.logger.bind(tag=TAG).info("Using the main LLM as the intent recognition model")

        """Load the unified tool handler"""
        self.func_handler = UnifiedToolHandler(self)

        # Asynchronously initialize the tool handler
        if hasattr(self, "loop") and self.loop:
            asyncio.run_coroutine_threadsafe(self.func_handler._initialize(), self.loop)

    def usage_attribution(self):
        """Device / agent / chat session of this connection, copied into every ai_usage row at call time."""
        return attribution_from_conn(self)

    def _track_llm_stream(self, stream, call_kind):
        """Write one ai_usage row (purpose chat) when the LLM stream ends, was aborted or failed."""
        scope = UsageScope("chat", self.usage_attribution(), call_kind=call_kind, llm=self.llm)
        return track_stream(stream, scope)

    def change_system_prompt(self, prompt):
        self.prompt = prompt
        # Update the system prompt into the context
        self.dialogue.update_system_message(self.prompt)

    def chat(self, query, depth=0):
        # Save the current task's sentence_id to a local variable so a new task cannot overwrite it
        current_sentence_id = None

        if query is not None:
            self.logger.bind(tag=TAG).info(f"LLM received user message: {query}")

        # At the top level, create a new session ID and send the FIRST request
        if depth == 0:
            current_sentence_id = str(uuid.uuid4().hex)
            self.sentence_id = current_sentence_id  # Update the shared attribute
            self.dialogue.put(Message(role="user", content=query))
            self.tts.tts_text_queue.put(
                TTSMessageDTO(
                    sentence_id=current_sentence_id,
                    sentence_type=SentenceType.FIRST,
                    content_type=ContentType.ACTION,
                )
            )
        else:
            # On recursive calls, use the current sentence_id
            current_sentence_id = self.sentence_id

        # Set the maximum recursion depth to avoid infinite loops; adjustable as needed
        MAX_DEPTH = 5
        force_final_answer = False  # Marks whether to force the final answer

        if depth >= MAX_DEPTH:
            self.logger.bind(tag=TAG).debug(
                f"Reached the maximum tool call depth {MAX_DEPTH}; forcing an answer based on the existing information"
            )
            force_final_answer = True
            # Add a system instruction requiring the LLM to answer based on the existing information
            self.dialogue.put(
                Message(
                    role="user",
                    content="[System notice] The maximum number of tool calls has been reached. Based on all the information obtained so far, give the final answer directly. Do not attempt to call any more tools.",
                )
            )

        # Define intent functions
        functions = None
        # When the maximum depth is reached, disable tool calls and force the LLM to answer directly
        if (
                self.intent_type == "function_call"
                and hasattr(self, "func_handler")
                and not force_final_answer
        ):
            functions = list(self.func_handler.get_functions())
            # Inject the direct_answer virtual tool only on the first-level call
            # Do not inject on recursive calls (depth>0), to prevent the model from calling direct_answer again while generating a text reply and causing a loop
            if functions is not None and depth == 0:
                functions.append(DIRECT_ANSWER_TOOL)

        response_message = []

        try:
            # Use the dialogue with memory
            memory_str = None
            # Query memory only when query is non-empty (i.e. the user asked something)
            if self.memory is not None and query:
                future = asyncio.run_coroutine_threadsafe(
                    self.memory.query_memory(query), self.loop
                )
                memory_str = future.result()

            # Inject the identity into system only when the speaker first appears; afterwards rely on the first turn kept in the dialogue history,
            # to avoid the name repeating in system every turn and inducing the model to address the user by name repeatedly
            speaker_for_system = None
            cs = (self.current_speaker or "").strip()
            if cs and cs != "Unknown speaker" and cs not in self.system_introduced_speakers:
                self.system_introduced_speakers.add(cs)
                speaker_for_system = cs

            if self.intent_type == "function_call" and functions is not None:
                # Use the streaming interface that supports functions
                llm_responses = self.llm.response_with_functions(
                    self.session_id,
                    self.dialogue.get_llm_dialogue_with_memory(
                        memory_str, self.config.get("voiceprint", {}), speaker_for_system
                    ),
                    functions=functions,
                )
                llm_responses = self._track_llm_stream(llm_responses, "chat_functions")
            else:
                llm_responses = self.llm.response(
                    self.session_id,
                    self.dialogue.get_llm_dialogue_with_memory(
                        memory_str, self.config.get("voiceprint", {}), speaker_for_system
                    ),
                )
                llm_responses = self._track_llm_stream(llm_responses, "chat")
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"LLM processing error {query}: {e}")
            return None

        # Handle the streaming response
        tool_call_flag = False
        # Supports multiple parallel tool calls - stored in a list
        tool_calls_list = []  # Format: [{"id": "", "name": "", "arguments": ""}]
        content_arguments = ""
        emotion_flag = True
        try:
            for response in llm_responses:
                if self.client_abort:
                    break
                if self.intent_type == "function_call" and functions is not None:
                    content, tools_call = response
                    if "content" in response:
                        content = response["content"]
                        tools_call = None
                    if content is not None and len(content) > 0:
                        content_arguments += content

                    if not tool_call_flag and content_arguments.startswith("<tool_call>"):
                        # print("content_arguments", content_arguments)
                        tool_call_flag = True

                    if tools_call is not None and len(tools_call) > 0:
                        tool_call_flag = True
                        self._merge_tool_calls(tool_calls_list, tools_call)

                    # Stream-extract the response parameter of direct_answer and send it to TTS in real time
                    # Use a safety buffer to prevent JSON closing symbols from leaking into TTS
                    _DA_STREAM_BUFFER = 5
                    for tc in tool_calls_list:
                        if tc["name"] == "direct_answer" and tc.get("arguments"):
                            da_text = self._extract_direct_answer_response(tc["arguments"])
                            sent_len = tc.get("_da_sent", 0)
                            if da_text and len(da_text) > sent_len:
                                safe_end = max(sent_len, len(da_text) - _DA_STREAM_BUFFER)
                                if safe_end > sent_len:
                                    new_part = da_text[sent_len:safe_end]
                                    # Clean up JSON closing garbage that may leak into the delta
                                    new_part = self._clean_response_garbage(new_part)
                                    if new_part:
                                        tc["_da_sent"] = safe_end
                                        self.tts.tts_text_queue.put(
                                            TTSMessageDTO(
                                                sentence_id=current_sentence_id,
                                                sentence_type=SentenceType.MIDDLE,
                                                content_type=ContentType.TEXT,
                                                content_detail=new_part,
                                            )
                                        )
                else:
                    content = response

                # Get the emotion emoji from the LLM reply; only once at the start of a dialogue turn
                if emotion_flag and content is not None and content.strip():
                    if (self.features or {}).get("emoji", True):
                        asyncio.run_coroutine_threadsafe(
                            textUtils.get_emotion(self, content),
                            self.loop,
                        )
                    emotion_flag = False

                if content is not None and len(content) > 0:
                    if not tool_call_flag:
                        response_message.append(content)
                        self.tts.tts_text_queue.put(
                            TTSMessageDTO(
                                sentence_id=current_sentence_id,
                                sentence_type=SentenceType.MIDDLE,
                                content_type=ContentType.TEXT,
                                content_detail=content,
                            )
                        )
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"LLM stream processing error: {e}")
            self.tts.tts_text_queue.put(
                TTSMessageDTO(
                    sentence_id=current_sentence_id,
                    sentence_type=SentenceType.MIDDLE,
                    content_type=ContentType.TEXT,
                    content_detail=get_system_error_response(self.config),
                )
            )
            if depth == 0:
                self.tts.tts_text_queue.put(
                    TTSMessageDTO(
                        sentence_id=current_sentence_id,
                        sentence_type=SentenceType.LAST,
                        content_type=ContentType.ACTION,
                    )
                )
            return
        finally:
            # Also on abort / error: ends the stream so its ai_usage row is written now
            llm_responses.close()
        # Handle function call
        if tool_call_flag:
            bHasError = False
            # Handle the text-based tool call format
            if len(tool_calls_list) == 0 and content_arguments:
                a = extract_json_from_string(content_arguments)
                if a is not None:
                    try:
                        content_arguments_json = json.loads(a)
                        tool_calls_list.append(
                            {
                                "id": str(uuid.uuid4().hex),
                                "name": content_arguments_json["name"],
                                "arguments": json.dumps(
                                    content_arguments_json["arguments"],
                                    ensure_ascii=False,
                                ),
                            }
                        )
                    except Exception as e:
                        bHasError = True
                        response_message.append(a)
                else:
                    bHasError = True
                    response_message.append(content_arguments)
                if bHasError:
                    self.logger.bind(tag=TAG).error(
                        f"function call error: {content_arguments}"
                    )

            if not bHasError and len(tool_calls_list) > 0:
                # Handle the direct_answer virtual tool
                direct_answer_calls = [tc for tc in tool_calls_list if tc["name"] == "direct_answer"]
                real_tool_calls = [tc for tc in tool_calls_list if tc["name"] != "direct_answer"]

                if direct_answer_calls:
                    self.logger.bind(tag=TAG).debug(
                        f"Model chose direct_answer; streaming already announced it; writing to dialogue history"
                    )
                    for tc in direct_answer_calls:
                        da_response = self._extract_direct_answer_response(tc.get("arguments", "{}"))
                        if da_response:
                            # Flush the unsent part of the streaming buffer
                            sent_len = tc.get("_da_sent", 0)
                            remaining = da_response[sent_len:]
                            if remaining:
                                remaining = self._clean_response_garbage(remaining)
                                if remaining:
                                    self.tts.tts_text_queue.put(
                                        TTSMessageDTO(
                                            sentence_id=current_sentence_id,
                                            sentence_type=SentenceType.MIDDLE,
                                            content_type=ContentType.TEXT,
                                            content_detail=remaining,
                                        )
                                    )
                            # Write to dialogue history
                            da_response = self._clean_response_garbage(da_response)
                            self.tts.store_tts_text(current_sentence_id, da_response)
                            self.dialogue.put(Message(role="assistant", content=da_response))

                    if not real_tool_calls:
                        if depth == 0:
                            self.tts.tts_text_queue.put(
                                TTSMessageDTO(
                                    sentence_id=current_sentence_id,
                                    sentence_type=SentenceType.LAST,
                                    content_type=ContentType.ACTION,
                                )
                            )
                        return

                    tool_calls_list = real_tool_calls

            if not bHasError and len(tool_calls_list) > 0:
                self.logger.bind(tag=TAG).debug(
                    f"Detected {len(tool_calls_list)} tool call(s)"
                )

                # Text already announced during the LLM streaming phase
                streamed_text = ""
                if len(response_message) > 0:
                    streamed_text = "".join(response_message)
                    self.tts.store_tts_text(current_sentence_id, streamed_text)
                    self.dialogue.put(Message(role="assistant", content=streamed_text))
                response_message.clear()

                # Collect the Futures of all tool calls
                futures_with_data = []
                for tool_call_data in tool_calls_list:
                    self.logger.bind(tag=TAG).debug(
                        f"function_name={tool_call_data['name']}, function_id={tool_call_data['id']}, function_arguments={tool_call_data['arguments']}"
                    )

                    # Report the tool call using the shared method
                    tool_input = json.loads(tool_call_data.get("arguments") or "{}")
                    enqueue_tool_report(self, tool_call_data['name'], tool_input)

                    future = asyncio.run_coroutine_threadsafe(
                        self.func_handler.handle_llm_function_call(
                            self, tool_call_data
                        ),
                        self.loop,
                    )
                    futures_with_data.append((future, tool_call_data, tool_input))

                # Tool call timeout, configurable, 30 seconds by default
                tool_call_timeout = int(self.config.get("tool_call_timeout", 30))
                # Wait for the coroutines to finish (the actual wait time is that of the slowest one)
                tool_results = []

                for future, tool_call_data, tool_input in futures_with_data:
                    try:
                        result = future.result(timeout=tool_call_timeout)
                        tool_results.append((result, tool_call_data))
                        # Report the tool call result using the shared method
                        enqueue_tool_report(self, tool_call_data['name'], tool_input, str(result.result) if result.result else None, report_tool_call=False)

                    except Exception as e:
                        self.logger.bind(tag=TAG).error(
                            f"Tool call timed out or failed: {tool_call_data['name']}, error: {e}"
                        )
                        # Return an error response on timeout so the whole flow does not hang
                        tool_results.append((
                            ActionResponse(action=Action.ERROR, result="Oops, the network ran into a problem. Please try again later!"),
                            tool_call_data
                        ))
                        # Report the tool call error
                        enqueue_tool_report(self, tool_call_data['name'], tool_input, str(e), report_tool_call=False)

                # Handle tool call results uniformly
                if tool_results:
                    self._handle_function_result(tool_results, depth=depth, streamed_text=streamed_text)

        # Store the dialogue content
        if len(response_message) > 0:
            text_buff = "".join(response_message)
            self.tts.store_tts_text(current_sentence_id, text_buff)
            self.dialogue.put(Message(role="assistant", content=text_buff))

        if depth == 0:
            self.tts.tts_text_queue.put(
                TTSMessageDTO(
                    sentence_id=current_sentence_id,
                    sentence_type=SentenceType.LAST,
                    content_type=ContentType.ACTION,
                )
            )
            # Use a lambda for lazy evaluation so get_llm_dialogue() runs only at DEBUG level
            self.logger.bind(tag=TAG).debug(
                lambda: json.dumps(
                    self.dialogue.get_llm_dialogue(), indent=4, ensure_ascii=False
                )
            )

        return True

    def _handle_function_result(self, tool_results, depth, streamed_text=""):
        need_llm_tools = []
        record_tools = []

        for result, tool_call_data in tool_results:
            if result.action in [
                Action.RESPONSE,
                Action.NOTFOUND,
                Action.ERROR,
            ]:
                text = result.response if result.response else result.result
                if streamed_text and text in streamed_text:
                    self.logger.bind(tag=TAG).debug(
                        f"Skipping duplicate TTS for tool {tool_call_data['name']}, already streamed"
                    )
                else:
                    self.tts.tts_one_sentence(self, ContentType.TEXT, content_detail=text)
                    self.tts.store_tts_text(self.sentence_id, text)
                self.dialogue.put(Message(role="assistant", content=text))
            elif result.action == Action.REQLLM:
                need_llm_tools.append((result, tool_call_data))
            elif result.action == Action.RECORD:
                record_tools.append((result, tool_call_data))
            else:
                pass

        # Action.RECORD: write the complete tool call chain(assistant(tool_calls) -> tool(result) -> assistant(response))
        # The model learns the tool-call pattern from history without an extra LLM call
        if record_tools:
            # Construct the assistant message (with tool_calls), recording "which tools the model called"
            all_tool_calls = [
                {
                    "id": tool_call_data["id"],
                    "function": {
                        "arguments": (
                            "{}"
                            if tool_call_data["arguments"] == ""
                            else tool_call_data["arguments"]
                        ),
                        "name": tool_call_data["name"],
                    },
                    "type": "function",
                    "index": idx,
                }
                for idx, (_, tool_call_data) in enumerate(record_tools)
            ]
            self.dialogue.put(Message(role="assistant", tool_calls=all_tool_calls))

            # Write each tool's execution result, recording "what the tool returned"
            for result, tool_call_data in record_tools:
                text = result.result or ""
                self.dialogue.put(
                    Message(
                        role="tool",
                        tool_call_id=(
                            str(uuid.uuid4())
                            if tool_call_data["id"] is None
                            else tool_call_data["id"]
                        ),
                        content=text,
                    )
                )

            # Use fixed text as the final reply to complete the standard three-part structure, so the next message is a user message rather than following a tool message
            response_parts = []
            for result, _ in record_tools:
                resp = result.response or result.result
                if resp:
                    response_parts.append(resp)
            if response_parts:
                self.dialogue.put(Message(role="assistant", content="，".join(response_parts)))

        if need_llm_tools:
            all_tool_calls = [
                {
                    "id": tool_call_data["id"],
                    "function": {
                        "arguments": (
                            "{}"
                            if tool_call_data["arguments"] == ""
                            else tool_call_data["arguments"]
                        ),
                        "name": tool_call_data["name"],
                    },
                    "type": "function",
                    "index": idx,
                }
                for idx, (_, tool_call_data) in enumerate(need_llm_tools)
            ]
            self.dialogue.put(Message(role="assistant", tool_calls=all_tool_calls))

            for result, tool_call_data in need_llm_tools:
                text = result.result
                if text is not None and len(text) > 0:
                    self.dialogue.put(
                        Message(
                            role="tool",
                            tool_call_id=(
                                str(uuid.uuid4())
                                if tool_call_data["id"] is None
                                else tool_call_data["id"]
                            ),
                            content=text,
                        )
                    )

            self.chat(None, depth=depth + 1)

    def _report_worker(self):
        """Chat history report worker thread"""
        while not self.stop_event.is_set():
            try:
                # Get data from the queue with a timeout so the stop event is checked periodically
                item = self.report_queue.get(timeout=1)
                if item is None:  # Detect the poison pill object
                    break
                try:
                    # Handled in order on this thread, so chat messages are stored in the order they happened
                    self._process_report(*item)
                except Exception as e:
                    self.logger.bind(tag=TAG).error(f"Chat history report thread error: {e}")
            except queue.Empty:
                continue
            except Exception as e:
                self.logger.bind(tag=TAG).error(f"Chat history report worker thread error: {e}")

        self.logger.bind(tag=TAG).info("Chat history report thread exited")

    def _process_report(self, type, text, audio_data, report_time):
        """Handle a report task"""
        try:
            # Perform the async report (runs in the event loop)
            asyncio.run(report(self, type, text, audio_data, report_time))
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Report handling error: {e}")
        finally:
            # Mark the task as done
            self.report_queue.task_done()

    def clearSpeakStatus(self):
        self.client_is_speaking = False
        self.logger.bind(tag=TAG).debug(f"Clearing the server speaking state")

    async def close(self, ws=None):
        """Resource cleanup method"""
        try:
            # Clean up VAD connection resources
            if (
                    hasattr(self, "vad")
                    and self.vad
                    and hasattr(self.vad, "release_conn_resources")
            ):
                self.vad.release_conn_resources(self)

            # Clean up the opus decoder
            if hasattr(self, "_connection_opus_decoder"):
                try:
                    delattr(self, "_connection_opus_decoder")
                except Exception:
                    pass

            # Clean up the audio buffer
            if hasattr(self, "audio_buffer"):
                self.audio_buffer.clear()

            # Cancel the timeout task
            if self.timeout_task and not self.timeout_task.done():
                self.timeout_task.cancel()
                try:
                    await self.timeout_task
                except asyncio.CancelledError:
                    pass
                self.timeout_task = None

            # Cancel the AEC cache cleanup task
            if hasattr(self, "_aec_cache_cleanup_task") and self._aec_cache_cleanup_task and not self._aec_cache_cleanup_task.done():
                self._aec_cache_cleanup_task.cancel()
                try:
                    await self._aec_cache_cleanup_task
                except asyncio.CancelledError:
                    pass
                self._aec_cache_cleanup_task = None

            # Clean up the AEC cache
            if hasattr(self, "aec_audio_cache"):
                self.aec_audio_cache.clear()
                self.aec_audio_cache_time.clear()

            # Clean up tool handler resources
            if hasattr(self, "func_handler") and self.func_handler:
                try:
                    await self.func_handler.cleanup()
                except Exception as cleanup_error:
                    self.logger.bind(tag=TAG).error(
                        f"Error while cleaning up the tool handler: {cleanup_error}"
                    )

            # Trigger the stop event
            if self.stop_event:
                self.stop_event.set()

            # Clear the task queues
            self.clear_queues()

            # Close the WebSocket connection
            try:
                if ws:
                    # Safely check the WebSocket state and close it
                    try:
                        if hasattr(ws, "closed") and not ws.closed:
                            await ws.close()
                        elif hasattr(ws, "state") and ws.state.name != "CLOSED":
                            await ws.close()
                        else:
                            # If there is no closed attribute, try closing directly
                            await ws.close()
                    except Exception:
                        # If closing fails, ignore the error
                        pass
                elif self.websocket:
                    try:
                        if (
                                hasattr(self.websocket, "closed")
                                and not self.websocket.closed
                        ):
                            await self.websocket.close()
                        elif (
                                hasattr(self.websocket, "state")
                                and self.websocket.state.name != "CLOSED"
                        ):
                            await self.websocket.close()
                        else:
                            # If there is no closed attribute, try closing directly
                            await self.websocket.close()
                    except Exception:
                        # If closing fails, ignore the error
                        pass
            except Exception as ws_error:
                self.logger.bind(tag=TAG).error(f"Error when closing the WebSocket connection: {ws_error}")

            if self.tts:
                await self.tts.close()
            if self.asr:
                await self.asr.close()

            # Finally close the thread pool (avoid blocking)
            if self.executor:
                try:
                    self.executor.shutdown(wait=False)
                except Exception as executor_error:
                    self.logger.bind(tag=TAG).error(
                        f"Error when closing the thread pool: {executor_error}"
                    )
                self.executor = None
            self.logger.bind(tag=TAG).info("Connection resources released")
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Error when closing the connection: {e}")
        finally:
            # Make sure the stop event is set
            if self.stop_event:
                self.stop_event.set()

    def clear_queues(self):
        """Clear all task queues"""
        if self.tts:
            self.logger.bind(tag=TAG).debug(
                f"Cleanup started: TTS queue size={self.tts.tts_text_queue.qsize()}, audio queue size={self.tts.tts_audio_queue.qsize()}"
            )

            # Clear the queues in a non-blocking way
            for q in [
                self.tts.tts_text_queue,
                self.tts.tts_audio_queue,
                self.report_queue,
            ]:
                if not q:
                    continue
                while True:
                    try:
                        q.get_nowait()
                    except queue.Empty:
                        break

            # Reset the audio flow controller (cancel background tasks and clear the queue)
            if hasattr(self, "audio_rate_controller") and self.audio_rate_controller:
                self.audio_rate_controller.reset()
                self.logger.bind(tag=TAG).debug("Audio flow controller reset")

            self.logger.bind(tag=TAG).debug(
                f"Cleanup finished: TTS queue size={self.tts.tts_text_queue.qsize()}, audio queue size={self.tts.tts_audio_queue.qsize()}"
            )

    def reset_audio_states(self):
        """
        Reset all audio related state (VAD + ASR)
        """
        # Reset VAD states
        self.client_audio_buffer.clear()
        self.client_have_voice = False
        self.client_voice_stop = False
        self.client_voice_window.clear()
        self.last_is_voice = False
        self.vad_last_voice_time = 0.0

        # Clear ASR buffers
        self.asr_audio.clear()

        self.logger.bind(tag=TAG).debug("All audio states reset.")

    def chat_and_close(self, text):
        """Chat with the user and then close the connection"""
        try:
            # Use the existing chat method
            self.chat(text)

            # After chat is complete, close the connection
            self.close_after_chat = True
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Chat and close error: {str(e)}")

    async def _check_timeout(self):
        """Check for connection timeout"""
        try:
            while not self.stop_event.is_set():
                last_activity_time = self.last_activity_time

                # Check for timeout (only when the timestamp has been initialized)
                if last_activity_time > 0.0:
                    current_time = time.time() * 1000
                    if current_time - last_activity_time > self.timeout_seconds * 1000:
                        if not self.stop_event.is_set():
                            self.logger.bind(tag=TAG).info("Connection timed out, preparing to close")
                            # Set the stop event to prevent duplicate handling
                            self.stop_event.set()
                            # Wrap the close operation in try-except to make sure exceptions cannot cause blocking
                            try:
                                await self.close(self.websocket)
                            except Exception as close_error:
                                self.logger.bind(tag=TAG).error(
                                    f"Error when closing the connection after timeout: {close_error}"
                                )
                        break
                # Check every 10 seconds to avoid being too frequent
                await asyncio.sleep(10)
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Timeout check task error: {e}")
        finally:
            self.logger.bind(tag=TAG).info("Timeout check task exited")

    async def _check_aec_cache_expiry(self):
        """Periodically clean up expired AEC cache"""
        try:
            while not self.stop_event.is_set():
                if hasattr(self, "aec_audio_cache") and self.aec_audio_cache:
                    current_time = time.time()
                    expired_keys = [
                        ts for ts, cache_time in list(self.aec_audio_cache_time.items())
                        if current_time - cache_time > 120  # Expires after 2 minutes
                    ]
                    for ts in expired_keys:
                        self.aec_audio_cache.pop(ts, None)
                        self.aec_audio_cache_time.pop(ts, None)
                    if expired_keys:
                        self.logger.bind(tag=TAG).debug(f"[AEC] Cleaned up {len(expired_keys)} expired cache entries")
                # Check every 30 seconds
                await asyncio.sleep(30)
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"AEC cache cleanup task error: {e}")

    @staticmethod
    def _extract_direct_answer_response(arguments_str):
        """Extract the response value from the direct_answer arguments.
        Prefer standard parsing with json.loads; fall back to string extraction during the streaming phase.
        """
        if not arguments_str:
            return ""
        # Prefer standard JSON parsing first (for complete and well-formed JSON)
        try:
            data = json.loads(arguments_str)
            if isinstance(data, dict) and "response" in data:
                return data["response"]
        except (json.JSONDecodeError, TypeError):
            pass
        # Fallback: JSON may be incomplete during streaming, so use string extraction
        marker = '"response": "'
        idx = arguments_str.find(marker)
        if idx < 0:
            marker = '"response":"'
            idx = arguments_str.find(marker)
        if idx < 0:
            return ""
        start = idx + len(marker)
        raw = arguments_str[start:]
        # Strip the trailing JSON closing symbols (if complete)
        if raw.endswith('"}'):
            raw = raw[:-2]
        elif raw.endswith('"'):
            raw = raw[:-1]
        # Handle JSON escapes
        raw = raw.replace('\\"', '"').replace('\\n', '\n').replace('\\\\', '\\')
        return raw

    @staticmethod
    def _clean_response_garbage(text):
        """Clean up JSON closing symbols that may have leaked into the response.
        The model sometimes generates JSON closing characters in the response content (e.g. ）"}} or '}),
        these are not part of the story content and must be removed.
        """
        if not text:
            return text
        # Clean up JSON closing garbage on a line by itself (e.g. ）"}}  '}}  "}}  }}  } ）
        _garbage_chars = frozenset('")\'}）')
        lines = text.split('\n')
        cleaned = []
        for line in lines:
            stripped = line.strip()
            if stripped and len(stripped) <= 8 and all(c in _garbage_chars for c in stripped):
                continue
            cleaned.append(line)
        result = '\n'.join(cleaned)
        # Clean up leftover JSON closing symbols at the end
        result = re.sub(r'["\'}\]]+$', '', result.rstrip()).rstrip()
        return result

    def _merge_tool_calls(self, tool_calls_list, tools_call):
        """Merge the tool call list

        Args:
            tool_calls_list: The tool call list collected so far
            tools_call: The new tool call
        """
        for tool_call in tools_call:
            tool_index = getattr(tool_call, "index", None)
            if tool_index is None:
                if tool_call.function.name:
                    # Has function_name, which means it is a new tool call
                    tool_index = len(tool_calls_list)
                else:
                    tool_index = len(tool_calls_list) - 1 if tool_calls_list else 0

            # Make sure the list has enough slots
            if tool_index >= len(tool_calls_list):
                tool_calls_list.append({"id": "", "name": "", "arguments": ""})

            # Update the tool call information
            if tool_call.id:
                tool_calls_list[tool_index]["id"] = tool_call.id
            if tool_call.function.name:
                tool_calls_list[tool_index]["name"] = tool_call.function.name
            if tool_call.function.arguments:
                tool_calls_list[tool_index]["arguments"] += tool_call.function.arguments
