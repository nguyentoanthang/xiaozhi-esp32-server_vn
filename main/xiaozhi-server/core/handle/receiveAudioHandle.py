import time
import json
import asyncio
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from core.connection import ConnectionHandler
from core.utils.util import audio_to_data
from core.handle.abortHandle import handleAbortMessage
from core.handle.intentHandler import handle_user_intent
from core.utils.output_counter import check_device_output_limit
from core.handle.sendAudioHandle import send_stt_message, SentenceType

TAG = __name__


async def handleAudioMessage(conn: "ConnectionHandler", pcm_frame):
    # Whether someone is speaking in the current segment
    have_voice = conn.vad.is_vad(conn, pcm_frame)
    # If the device was just woken up, briefly ignore VAD detection
    if hasattr(conn, "just_woken_up") and conn.just_woken_up:
        have_voice = False
        # Restore VAD detection after a short delay
        if not hasattr(conn, "vad_resume_task") or conn.vad_resume_task.done():
            conn.vad_resume_task = asyncio.create_task(resume_vad_detection(conn))
        return
    # The server-side AEC feature needs to trigger aborts in real time
    if conn.client_aec and have_voice:
        if conn.client_is_speaking and conn.client_listen_mode != "manual":
            await handleAbortMessage(conn)
    # Detect long device idle time, used to say goodbye
    await no_voice_close_connect(conn, have_voice)
    # Receive audio
    await conn.asr.receive_audio(conn, pcm_frame, have_voice)


async def resume_vad_detection(conn: "ConnectionHandler"):
    # Restore VAD detection after waiting 2 seconds
    await asyncio.sleep(2)
    conn.just_woken_up = False


async def startToChat(conn: "ConnectionHandler", text, display_text=None):
    """Start a chat turn. `text` is what the LLM, dialogue and logs see (already masked by the guardrail).

    `display_text` is the same input before masking, in the same form (plain text or the speaker JSON);
    it is only shown on the device as the subtitle and never logged, stored or sent to the LLM.
    """
    # Check whether the input is JSON (containing speaker info)
    speaker_name = None
    actual_text = text
    # Unmasked counterpart of actual_text, for the device subtitle only
    shown_text = None

    try:
        # Try to parse JSON input
        if text.strip().startswith("{") and text.strip().endswith("}"):
            data = json.loads(text)
            if "speaker" in data and "content" in data:
                speaker_name = data["speaker"]
                actual_content = data["content"]
                conn.logger.bind(tag=TAG).info(f"Parsed speaker info: {speaker_name}")

                # Keep the {"speaker":...} JSON only the first time this speaker appears, so the model addresses them naturally once;
                # later turns fall back to plain text, to avoid the name repeating every turn and inducing the model to keep addressing them
                if speaker_name not in conn.introduced_speakers:
                    conn.introduced_speakers.add(speaker_name)
                    actual_text = text
                else:
                    actual_text = actual_content
                if display_text is not None:
                    shown_text = display_text
                    shown = json.loads(display_text)
                    if actual_text is not text:
                        shown_text = shown["content"]
    except (json.JSONDecodeError, KeyError):
        # If parsing fails, keep using the original text
        pass

    if shown_text is None:
        shown_text = display_text if display_text is not None else actual_text
    # Subtitle text for the stt message (the intent handler reads it too)
    conn.stt_display_text = shown_text

    # Save speaker info to the connection object
    if speaker_name:
        conn.current_speaker = speaker_name
    else:
        conn.current_speaker = None

    # If the day's output word count exceeds the limit
    if conn.max_output_size > 0:
        if check_device_output_limit(
            conn.headers.get("device-id"), conn.max_output_size
        ):
            await max_out_size(conn)
            return

    # In manual mode, do not interrupt content that is currently playing
    if conn.client_is_speaking and conn.client_listen_mode != "manual":
        await handleAbortMessage(conn)

    # First run intent analysis, using the actual text content
    intent_handled = await handle_user_intent(conn, actual_text)

    if intent_handled:
        # If the intent has been handled, do not chat
        return

    # Intent not handled, continue the normal chat flow, using the actual text content
    await send_stt_message(conn, shown_text)

    # Prepare to start a new session
    conn.client_abort = False

    conn.executor.submit(conn.chat, actual_text)


async def no_voice_close_connect(conn: "ConnectionHandler", have_voice):
    if have_voice:
        conn.last_activity_time = time.time() * 1000
        return
    # Only do the timeout check if the timestamp has already been initialized
    if conn.last_activity_time > 0.0:
        no_voice_time = time.time() * 1000 - conn.last_activity_time
        close_connection_no_voice_time = int(
            conn.config.get("close_connection_no_voice_time", 120)
        )
        if (
            not conn.close_after_chat
            and no_voice_time > 1000 * close_connection_no_voice_time
        ):
            conn.close_after_chat = True
            conn.client_abort = False
            end_prompt = conn.config.get("end_prompt", {})
            if end_prompt and end_prompt.get("enable", True) is False:
                conn.logger.bind(tag=TAG).info("Ending the conversation, no closing prompt needed")
                await conn.close()
                return
            prompt = end_prompt.get("prompt")
            if not prompt:
                prompt = "Please begin with ```Time flies``` and end this conversation with affectionate, reluctant words."
            await startToChat(conn, prompt)


async def max_out_size(conn: "ConnectionHandler"):
    # Play the prompt for exceeding the maximum output word count
    conn.client_abort = False
    text = "Sorry, I have something to take care of right now. Let us talk again at this time tomorrow, it is a promise! See you then, bye!"
    await send_stt_message(conn, text)
    file_path = "config/assets/max_output_size.wav"
    opus_packets = await audio_to_data(file_path)
    conn.tts.tts_audio_queue.put((SentenceType.LAST, opus_packets, text))
    conn.close_after_chat = True
