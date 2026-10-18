# Testing progress: 2026-10-18

Tests ran in the existing Conda environment `xiaozhi-esp32-server` (Python 3.10.22).
Initial runs did not change packages. After the isolated 7.3.0 probe passed and the user approved,
only Edge TTS was upgraded from 7.2.8 to 7.3.0; `requirements.txt` now pins 7.3.0.
The checksum-verified wheel was installed with `--no-deps`. `pip check` passed before and after.

## Configuration

Latest continuation: [device-free checklist report](./headless-checklist-test-2026-10-18.md).
Real WebSocket/browser tests now verify history/audio/titles, memory reconnect/isolation,
usage attribution/views, concurrent clients, interruption, voice/replacement options, MCP/OTA,
and restart recovery. The ten-sentence English run scored 10/10 normalized exact transcripts.
The one-hour idle test also passed: 3,600.4 seconds on the same connection/ASR instance, followed by
successful speech recognition and 51 reply audio packets. Only verified completed items are checked in Part 2.
Four gaps remain open: spoken number words bypass masking, trailing placeholders break restoration,
explicit exit skips the enabled end prompt, and an ASR-key failure gives no system error reply.

- The main database now selects `deepseek/deepseek-v4.1-flash-1017` for LLM, restricted to `relace` with provider/model fallbacks disabled, and `elevenlabs/scribe-v2` for ASR. Earlier Gemma failures below are retained as test history.
- The default agent's voice is `vi-VN-HoaiMyNeural`.
- Both providers load the key from `main/xiaozhi-server/.env`. OpenRouter key fields in the database remain empty.
- A scan of the server, live LLM, and WebSocket test logs found no occurrence of the actual API key.
- The main database passes `PRAGMA integrity_check`.

## Results

| Test | Result | Evidence and scope |
|---|---|---|
| Latest full pytest suite (7.3.0) | 280 passed, 15 skipped | English test-only voice; fresh `--basetemp`; all four TTS tests pass. One cache permission warning; no test failures/errors |
| Earlier full pytest suite (7.2.8) | 279 passed, 1 failed, 15 skipped | Failure was `tests/test_tts.py::test_tts_text_to_speak_writes_file` |
| Edge TTS pytest retry with network enabled | 3 passed, 1 failed | The same synthesis test receives HTTP 403, confirming a service/protocol failure after the sandbox restriction is removed |
| Scribe transcription | Passed | Two 10-second bundled Chinese audio samples returned nonempty transcripts using PCM; latest request took 2,436 ms. Vietnamese recognition accuracy is untested |
| Scribe usage | Passed | Each successful request recorded `audio_seconds=10`, requested model, device/agent attribution, and cost approximately USD 0.000305556 |
| Scribe invalid key | Passed | HTTP 401 returns `("", None)` without raising to the caller and writes no usage row |
| Gemma streaming acceptance (L1) | Failed | HTTP 429; API metadata says the free model is temporarily rate-limited upstream; no response chunks |
| Gemma Vietnamese reply | Failed | A separate short Vietnamese question also received HTTP 429 |
| DeepSeek / Relace minimal streaming | Passed | One request through the server LLM provider returned exactly `OK`; 9 input tokens, 2 output tokens, 0 reasoning tokens, finish reason `stop`, reported cost USD 0.00000165, duration 2,577 ms. Relace-only routing with fallbacks disabled was sent. Full L1 and conversation acceptance remain unverified |
| English ASR -> LLM workflow | Passed | Local English WAV -> real Scribe provider -> actual transcript passed unchanged to real DeepSeek provider restricted to Relace -> correct English answer. 4.9-second audio, total elapsed 3,047 ms; one ASR call and one LLM call |
| English workflow usage | Passed | Exactly one STT and one chat LLM row with matching session/device/agent. STT cost USD 0.000149722222222195, LLM cost USD 0.00000505; total USD 0.000154772222222195. LLM used 17 input / 7 output tokens |
| English ASR -> LLM -> TTS workflow (7.3.0) | Passed | One Scribe call -> actual transcript -> one DeepSeek/Relace call -> actual answer synthesized by server Edge TTS provider. Saved/decoded non-silent 2.616-second MP3, 15,696 bytes, 24 kHz mono; total elapsed 3,579 ms |
| LLM invalid model/key acceptance (L6) | Passed | `1 passed, 9 deselected`; invalid model gives HTTP 400, invalid key gives HTTP 401, and each emits exactly one error usage record |
| Vietnamese Edge TTS | Failed | Actual server provider, `vi-VN-HoaiMyNeural`, Vietnamese text: HTTP 403 from `speech.platform.bing.com` using installed `edge_tts==7.2.8`; no valid audio |
| Server startup and OTA | Passed | Actual `app.py` starts against a database copy; OTA endpoint returns HTTP 200 |
| WebSocket hello and registration | Passed | Real client receives `hello` with session ID; uppercase test MAC is stored lowercase, with agent `default` and `last_connected_at` |
| Refuse unknown device | Passed | Disable auto-registration, delete test device, reconnect: `device_refused`, connection closes, and no device row is created. Auto-registration restored in the test copy |
| Connection logs | Passed | No `NoDefaultAgent` or traceback for accepted/refused connections |

The two successful Scribe calls total 20 seconds and approximately **USD 0.000611111** in reported usage.
The first provider harness stopped after transcription because of a harness argument error; that is why
two successful transcription rows exist. The harness was corrected and the combined provider run completed.

The later DeepSeek check made one paid inference request, limited to 32 output tokens with reasoning
disabled and no retries. An initial sandbox attempt was blocked before reaching OpenRouter and was
rerun with network access. A generation-details GET returned HTTP 404; backend identity was
constrained by `provider.only=["relace"]`, but not independently confirmed by generation metadata.
The usage row labels the integration `openrouter`, not the backend. At that stage no other paid LLM checks were run; the subsequent English workflow below adds one LLM call.
The output limit and disabled reasoning were test-only overrides, not saved as server defaults.

Scribe's passing transcription supplied the model and API key without a backend provider pin.
OpenRouter handles routing; the server ASR adapter does not send a `provider` object, and the STT
response did not identify the backend. [OpenRouter's transcription documentation](https://openrouter.ai/blog/tutorials/transcription-on-openrouter/)
explains that the optional STT provider object carries provider-specific options; chat routing controls do not apply.

## English ASR-to-LLM workflow

All new testing uses English as requested. Earlier Chinese/Vietnamese results remain historical.
An installed Windows voice, Microsoft David Desktop (`en-US`), generated a local 16 kHz mono
16-bit WAV saying: "What is two plus two? Answer in one short English sentence."
Scribe returned that exact text. The harness passed this actual transcript unchanged as the sole
LLM user message. DeepSeek, restricted to Relace with no fallbacks, replied:
"Two plus two equals four."

Only one transcription and one LLM inference were needed. ASR retries and format fallback were
disabled; LLM output was capped at 32 tokens with reasoning disabled. Both usage records have
session `english-asr-llm-1792311706`, device `02:00:00:00:00:94`, and agent `default`.
No packages were installed. English language/response limits were harness-only overrides; the main
database voice and ASR language were not changed. Windows synthesis only prepared the input fixture;
it does not constitute a successful test of the server's Edge TTS reply path.

This confirms the provider-level audio-to-transcript-to-answer workflow. It does not yet confirm
microphone capture, VAD/Opus/WebSocket conversation dispatch, audible reply TTS, or physical device behavior.

## Approved Edge TTS upgrade and complete English workflow

The installed 7.3.0 server provider synthesized the actual new LLM reply,
"Two plus two equals four.", with `en-US-JennyNeural`. Decoding confirmed 2,616 ms of mono
24 kHz audio with RMS 3,394. No subjective listening or physical speaker verification was performed.
This new workflow used one 4.9-second Scribe request (USD 0.000149722222222195) and one
DeepSeek/Relace request (17 input / 7 output tokens; USD 0.00000505), totaling
USD 0.000154772222222195 in reported paid usage. The LLM output cap was 32 tokens,
reasoning was disabled, and provider/model fallbacks and ASR retries were disabled.
The test voice and language overrides were not saved to the main database.

The initial regression attempt encountered an inaccessible existing Windows pytest temporary
directory (168 passed, 15 skipped, 112 setup errors). Rerunning with a fresh repository-local
`--basetemp` resolved those setup errors: **280 passed, 15 skipped** in 25.54 seconds.
All four TTS tests passed with an English voice override. The only remaining warning is permission
to write pytest's cache; it does not affect assertions. Skips were reviewed: 10 opt-in paid live
OpenRouter cases, 3 placeholder-key LLM cases, and 2 configuration-dependent module checks.
`pip check` reports no broken requirements, the main database integrity is `ok`, and its
OpenRouter key fields remain empty. `git diff --check` passes.

## Evidence files

Paths below are relative to `main/xiaozhi-server`; `tmp/` is Git-ignored.

- `tmp/configured_provider_results.json`: latest STT, bad-key, Vietnamese TTS, and Vietnamese LLM results.
- `tmp/configured_provider_tests.db`: provider-only usage evidence; separate from the main database.
- `tmp/configured_openrouter_live_results.json`: failed Gemma L1 acceptance findings and upstream rate-limit metadata.
- `tmp/configured_openrouter_errors.json`: passed L6 invalid-key/model findings.
- `tmp/relace_minimal_results.json` and `tmp/relace_minimal.db`: DeepSeek/Relace streaming result and isolated usage evidence.
- `tmp/english_asr_to_llm_results.json`, `tmp/english_asr_to_llm.db`: English chained provider test and usage evidence.
- `tmp/test_english_asr_to_llm.py`, `tmp/english-asr-llm-question.wav`: executed harness and known English input recording. Rerunning makes paid API calls.
- `tmp/test_english_asr_llm_tts.py`, `tmp/english_asr_llm_tts_results.json`, `tmp/english_asr_llm_tts.db`: complete provider workflow harness, result and isolated usage evidence. Rerunning makes paid API calls.
- `tmp/english-asr-llm-tts-reply.mp3`: generated English answer; listener playback remains unverified.
- `tmp/english-pytest-config.yaml`, `tmp/pytest-edge730-results.txt`: English test-only override and passing regression output.
- `tmp/configured_websocket_results.json`: real server/client handshake, registration, refusal, and integrity results.
- `tmp/configured_websocket_server.log`: captured real server output.
- `tmp/websocket_acceptance_1792310706.db`: copied database used for WebSocket checks.

The temporary server was stopped after testing. Only the requested model selections and Vietnamese voice
were changed in the main database; test devices and usage rows were written to isolated databases.

## Remaining work

1. Basic LLM access and the English provider-level ASR-to-LLM workflow now pass. Broader paid LLM acceptance tests remain deferred to keep cost low as requested.
2. Edge TTS's earlier HTTP 403 is resolved in the tested 7.3.0 English path. The complete provider workflow
   now passes. Listen to the generated MP3 to verify audible content/quality; no listener verification is claimed.
3. Headless speech/history/audio/memory, tool dispatch, interruption, timeout, concurrency and crash recovery
   checks now have evidence in the device-free report. Resolve its four recorded software gaps before
   treating the speech paths as fully accepted. Separate LLM tests L2-L5 and L7-L10 were not all run as standalone cases.
4. The later user-requested [Vietnamese review](./vietnamese-conversation-test-2026-10-18.md) completed three two-turn provider conversations,
   with six correct written answers and valid final audio files. Two initial TTS calls returned no audio;
   retries of saved answers succeeded. Total reported paid cost USD 0.000648833333333229.
   User listening confirmation and uninterrupted Vietnamese TTS reliability remain unverified.
5. Physical-device boot/screen/playback/flashing, Docker, actual PC network interruption, and the OpenRouter
   dashboard cost comparison remain unverified. The headless one-hour idle and simulated transport-reconnect
   checks passed. Docker is unavailable; local FunASR comparison needs its missing model file.

See [Part 2 of the guide](./setup-test-measure-guide.md#part-2-test-checklist) for the checklist.
