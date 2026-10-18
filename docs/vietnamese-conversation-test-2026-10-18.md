# Vietnamese conversation review — 2026-10-18

Three two-turn conversations completed through real Scribe ASR, DeepSeek through Relace, and Edge TTS 7.3.0.
Six transcriptions and six LLM requests were used. Total reported ASR/LLM cost: **USD 0.000648833333333229**.
LLM replies were capped at 80 tokens with reasoning disabled and provider/model fallbacks disabled.

[Open the audio review page](../main/xiaozhi-server/tmp/vietnamese-review-1792312499/review.html)
to listen to the complete conversations or each question/answer separately, and compare transcripts.
Artifacts are local and Git-ignored; retain the folder if you want to keep the audio evidence.

Input audio was synthesized with `vi-VN-NamMinhNeural`; replies used `vi-VN-HoaiMyNeural`.
The harness sent actual audio to `elevenlabs/scribe-v2`, passed the actual transcript to
`deepseek/deepseek-v4.1-flash-1017` restricted to `relace`, and synthesized the actual answer.
Conversation history was held by the harness. There was no microphone, ESP32, VAD/Opus transport,
WebSocket conversation dispatch, or database memory/history acceptance test in this run.
No packages or production configuration were changed for these language tests.

## 1. Arithmetic and follow-up

[Listen to both turns](../main/xiaozhi-server/tmp/vietnamese-review-1792312499/conversation-1.wav)

| Turn | Actual ASR transcript | Actual LLM answer |
|---|---|---|
| 1 | Hai cộng hai bằng mấy? | Hai cộng hai bằng bốn. |
| 2 | Lấy kết quả đó nhân với ba thì bằng mấy? | Lấy bốn nhân với ba bằng mười hai. |

Both transcripts matched their input text. Answers were correct and the follow-up used the previous result.

## 2. Geography and follow-up

[Listen to both turns](../main/xiaozhi-server/tmp/vietnamese-review-1792312499/conversation-2.wav)

| Turn | Actual ASR transcript | Actual LLM answer |
|---|---|---|
| 1 | Thủ đô của Việt Nam là thành phố nào? | Thủ đô của Việt Nam là Hà Nội. |
| 2 | Thành phố đó nằm ở miền nào của Việt Nam? | Hà Nội nằm ở miền Bắc Việt Nam. |

Both transcripts matched their input text. Answers were correct and the follow-up resolved the city from context.

## 3. Name and conversation context

[Listen to both turns](../main/xiaozhi-server/tmp/vietnamese-review-1792312499/conversation-3.wav)

| Turn | Actual ASR transcript | Actual LLM answer |
|---|---|---|
| 1 | Tôi tên là Minh. Hãy chào tôi bằng một câu ngắn | Chào Minh, rất vui được gặp bạn! |
| 2 | Tôi vừa nói tên mình là gì? | Bạn vừa nói tên mình là Minh. |

The first transcript omitted the final period; spoken content was preserved. The second turn recalled
the name from the messages supplied by the harness. This does not verify server persistent memory.

## Failures, recovery, and review status

Two initial female reply syntheses returned `No audio was received`: arithmetic turn 2 and geography turn 1.
Those conversations did not pass uninterrupted. Retrying the saved answer text produced valid audio;
the paid ASR/LLM calls were not repeated for these retries. The remaining geography follow-up used one
new ASR/LLM pair, bringing the final total to six of each. Initial findings remain in
`main/xiaozhi-server/tmp/vietnamese-review-1792312499/results-initial.json`;
final results and usage evidence are in `results.json` and `usage.db` in that folder.
Vietnamese TTS therefore works in these examples but still showed intermittent no-audio failures.

The first combined MP3 review export was invalid because the local FFmpeg build lacks an MP3 encoder.
The review files were rebuilt as WAV and decoded successfully. Individual Edge-generated MP3 files
are valid. This was a test artifact issue; the server TTS code was not changed.

- [x] All six transcriptions preserve the intended Vietnamese speech content.
- [x] All six written replies contain the expected answer; each conversation's follow-up retains context.
- [x] All six final reply MP3s and all three combined WAVs decode to non-silent audio.
- [x] Each conversation records two STT and two LLM usage rows in an isolated database.
- [ ] All conversations complete without TTS failures or manual retries — two initial calls failed.
- [ ] User confirms pronunciation, audible content, and voice quality after listening.
- [ ] Physical microphone/ESP32 full conversation works.
