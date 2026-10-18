# Tests without an ESP32 — 2026-10-18

Tests used the existing Conda environment, the installed Edge TTS 7.3.0, copied SQLite databases, actual server code, and real WebSocket clients. No additional packages or models were installed. Production code and the main configuration were not edited for this run. English was used throughout.

## Verified behavior

| Area | Result | Scope |
|---|---|---|
| Speech conversation | Passed | English WAV encoded as Opus -> real WebSocket -> Scribe -> DeepSeek/Relace -> streamed reply audio and STT subtitle |
| History | Passed | Ordered user/assistant rows, ended_at, title, summary; mode 1 stores text without audio; mode 0 stores no conversation history |
| Stored audio | Passed | Both user and assistant clips unpack and decode as non-silent Opus audio; temporary WAV exports are available with the evidence |
| Memory | Passed | Rex saved as JSON and recalled after reconnect; another MAC independently remembers Luna; nomem preserves the prior row |
| Guardrails on recognized text | Passed | Numeric phone/card, email and configured name mask correctly; repeated phone numbering is stable; original text appears only in the subtitle on this path; disabling the setting works |
| Guardrails on real speech | Partial/failure | Spoken email and configured name masked correctly; phone/card returned as number words were not masked; see defects below |
| Usage | Passed | One real audio session has STT, chat, title and memory rows with correct session/device/agent and non-null costs; agent reassignment preserves old rows; views match manual known-session counts |
| TTS options | Passed | English voice changes on reconnect; replacement word changes only actual TTS input, preserving displayed/stored text |
| Missing LLM key | Passed for recognized-text input | Error reply and audio were returned; OTA still answered HTTP 200. Missing ASR key behaves differently; see defects |
| MCP endpoint | Passed | Local protocol fixture received initialize/tools-list; server listed headless_echo and reported ready |
| Device-tool protocol | Passed with simulated device | Spoken volume command led to self.audio_speaker.set_volume(volume=25), simulated acknowledgement and reply audio; no physical volume change is claimed |
| Plugins disabled | Passed | Actual setting false; weather question did not execute a weather/music plugin. Corrected evidence audit removes an erroneous log-string requirement in the first harness |
| Firmware OTA | Passed | Synthetic non-flashable fixture offered only to an older matching model/version, URL used http_base_url, downloaded bytes matched, same-version client got no update; fixture removed |
| Concurrency | Passed | Two simultaneous scripted clients received correct audio replies; no database-is-locked error |
| Interruption | Passed at protocol level | Abort while audio streaming returned stop, then a new question received a correct audio answer |
| Exit/silence | Partial | goodbye/exit/quit close the connection; silence closes with end prompt disabled and speaks/closes with it enabled; explicit exit skips enabled end prompt |
| Crash/restart | Passed | Abrupt termination during a conversation; restart passed integrity check, preserved recorded rows and accepted reconnect |
| Transport outage | Passed as simulation | Client transport aborted for 30 seconds, then reconnected and received reply audio; PC network adapter was not disabled |
| Browser client | Passed | Actual headless Edge rendered the digital-human UI, connected through OTA, displayed conversation and received 234 audio frames; fake microphone/camera and a separate profile were used; no JavaScript exceptions |
| One-hour idle | passed | 60/60 minutes recorded; same server/client, extended test-only no-voice timeout, WebSocket pings; final ASR/LLM/audio reply required |

## Confirmed gaps — checklist remains open

1. **Spoken phone/card values can bypass masking.** Real English speech produced `zero nine one two three four five six seven eight` and card digits as words. These did not match digit-based patterns, reached stored messages and normal INFO logs, and were therefore available to the LLM. Email and John Smith were masked; Alice Johnson was preserved. The card transcription also needs review for digit fidelity. This is distinct from the passing recognized-numeric-text test.

2. **Restoration fails when a reply ends with a placeholder.** Captured actual TTS input was `You said your phone is [PHONE_1` rather than the restored number. `ConnectionHandler._clean_response_garbage` strips trailing `]`, preventing the guardrail from matching the complete token. Stored reply and client text contained the same truncated placeholder.

3. **Explicit exit ignores the enabled end prompt.** With `end_prompt.enable=true`, sending goodbye closed the WebSocket with zero audio packets. `check_direct_exit` calls close directly. The idle-silence goodbye path did speak the configured prompt.

4. **Missing ASR key gives no spoken/system error reply.** A real audio question with the OpenRouter key blank failed ASR and returned no reply before the 50-second observation timeout, although the process remained alive. A recognized-text question did receive the LLM system-error reply.

These are test findings; application fixes have not been applied.

## Ten-sentence OpenRouter run

Normalized exact transcripts: **10/10**. All ten replies had audio: **True**. Normalization removes punctuation and case only.

Median `listen.stop` to first outgoing audio packet: **3.249 seconds**. This measures a protocol event, not sound arriving at a physical speaker. Server RSS before a conversation: **121.47 MiB**; observed peak: **146.02 MiB**. This is one scripted run, not publication-grade repeated benchmarking.

Reported STT cost: **USD 0.00070950**; whole ten-turn session including chat/title: **USD 0.00126772**. Local FunASR could not be compared because `models/SenseVoiceSmall/model.pt` is absent; the Python package is available. No model download was attempted.

| # | Input | Actual transcript | Exact after normalization |
|---|---|---|---|
| 1 | Please turn on the light. | Please turn on the light | True |
| 2 | What is your name? | What is your name? | True |
| 3 | My dog is called Rex. | My dog is called Rex | True |
| 4 | Please speak more slowly. | Please speak more slowly | True |
| 5 | Tell me a short story. | Tell me a short story | True |
| 6 | What is the capital of France? | What is the capital of France? | True |
| 7 | I would like a cup of coffee. | I would like a cup of coffee | True |
| 8 | Remind me to call my friend. | Remind me to call my friend | True |
| 9 | How are you today? | How are you today? | True |
| 10 | Thank you for your help. | Thank you for your help | True |

## Evidence and verification

All paths below are relative to `main/xiaozhi-server`; these artifacts are Git-ignored. The copied databases contain synthetic test identities only for the newly inserted sessions.

- Core acceptance: `tmp/headless-acceptance-1792313466/results.json` and `tmp/headless-acceptance-1792313466/test.db`.
- Protocol options: `tmp/headless-protocol-1792313591/results.json` and `tmp/headless-protocol-1792313591/test.db`.
- Spoken guardrails: `tmp/headless-spoken-guardrails-1792314155/results.json` and `tmp/headless-spoken-guardrails-1792314155/test.db`.
- Phone audio at INFO/DEBUG: `tmp/headless-audio-privacy-1792313706/results.json` and `tmp/headless-audio-privacy-1792313706/test.db`.
- Error and end-prompt cases: `tmp/headless-edge-cases-1792314000/results.json` and `tmp/headless-edge-cases-1792314000/test.db`.
- Browser: `tmp/headless-browser-1792313923/results.json` and `tmp/headless-browser-1792313923/test.db`.
- Simulated device tool: `tmp/headless-device-tool-1792313797/results.json` and `tmp/headless-device-tool-1792313797/test.db`.
- Ten sentences: `tmp/headless-ten-sentences-1792314101/results.json` and `tmp/headless-ten-sentences-1792314101/test.db`.
- All four usage purposes: `tmp/headless-complete-usage-1792314324/results.json` and `tmp/headless-complete-usage-1792314324/test.db`.
- Consolidated audit: `tmp/headless-audit.json`; includes exact view totals and decoded audio metadata.
- One-hour idle: `tmp/headless-idle-1792313329/idle-results.json` and `server.log`.
- Browser screenshot: `tmp/headless-browser-1792313923/browser.png`. Static files were served locally; the desktop wake-word runtime was not started, and physical microphone/speaker quality was not checked.

Total reported paid usage across this round of headless test databases: **USD 0.00723464** (113 usage records, deduplicated by record ID). This includes additional short browser turns because the fake microphone file loops; the browser was stopped after verification. No dashboard comparison is claimed.

Main database integrity: `ok`. New headless device MACs found in main database: `0`. Main database OpenRouter key fields empty: `True`. Actual key found in inspected headless logs: `False`.

## Still requires external prerequisites or human confirmation

- Physical ESP32 boot, screen output, real speaker playback/volume, and actual firmware flashing.
- User listening confirmation for the earlier Vietnamese recordings.
- Docker build/start: Docker is unavailable in this shell.
- FunASR comparison: missing local model file.
- OpenRouter dashboard comparison: dashboard access was not available.
- Physical PC network disconnect/reconnect: only an isolated client transport outage was simulated.
- Desktop microphone/speaker and optional local wake-word service: fake browser devices were used.

The one-hour idle test passed after 3600.4 seconds; final reply: `Four — two plus two is four`. It returned 51 audio packets; first outgoing audio arrived 4.39 seconds after `listen.stop`. The test-only no-voice timeout was 4,000 seconds; the same ASR instance and WebSocket were retained. All temporary test servers and the isolated browser were stopped afterward.
