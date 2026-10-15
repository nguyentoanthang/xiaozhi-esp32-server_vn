# Plan: Remove Chinese Support (personal fresh-install server)

## Goal
Remove Chinese as a supported language entirely. This is a personal, fresh-install
server, so there is no need to keep compatibility with old databases, stored data,
or existing Liquibase checksums.

## Decisions
- Remove only Chinese locales (zh_CN, zh_TW). Keep en, de, vi, pt_BR. Default locale becomes `en`.
- Chinese-only providers and plugins are kept for now (see "Deferred"). They only run
  if selected, so they have no runtime effect.
- Wake words are not decided yet. They are added later in config (see "Wake words").
- Liquibase changesets may be rewritten freely (fresh DB only).

## Work items

### 1. Delete
- Web: `src/i18n/zh_CN.js`, `zh_TW.js`, `src/assets/xiaozhi-ai_zh_*.png`, Chinese public pages
  (`public/privacy-policy.html`, `public/user-agreement.html`) and the whole `public/generator`
  (ESP wake-word/font generator with Chinese models and fonts), plus its button and i18n key in `DeviceManagement.vue`.
- Mobile: `src/i18n/zh_CN.ts`, `zh_TW.ts`, `login/privacy-policy-zh.vue`, `login/user-agreement-zh.vue`.
- API: `messages_zh_*.properties`, `validation_zh_*.properties`.
- Live2D Chinese licence readmes (`digital-human/resources/*_zh`).

### 2. Fix references to the deleted locales
- Web: `i18n/index.js` (imports, element-ui zh locales, default/fallback `zh_CN`), `HeaderBar.vue`,
  `login.vue`, `register.vue`, `retrievePassword.vue`, `httpRequest.js`, `scripts/check-i18n.js`.
- Mobile: `store/lang.ts`, `login/index.vue`, `alova.ts`, pages that link the zh policy pages.
- API: `WebMvcConfig`, `HttpContextUtils` (default `Locale.SIMPLIFIED_CHINESE`), `AgentUpdateDTO`.

### 3. Replace Chinese-coupled logic
- Placeholder marker: replace the `你` / `你的` checks (`app.py`, `util.py`, `http_server.py`,
  `ota_handler.py`, `mcp_endpoint_handler.py`, Java `RAGFlowAdapter`, web mask text, config, SQL)
  with one English marker (e.g. `your_`), applied consistently.
- Language data: weekday maps and lunar output (`current_time.py`, `prompt_manager.py`, `get_time.py`),
  `未知说话人`, `"中文"` / `普通话` language values and the voice `languages` column (`TimbreServiceImpl`
  splits on `、`), Chinese punctuation tables and CJK range checks (`tts.py`, `textUtils.py`, `util.py`).
- Seed data (SQL): translate all remaining Chinese, drop Chinese-only voices where appropriate.
- Config and misc: remaining Chinese in `config.yaml`, `mcp_server_settings.json`,
  `agent-base-prompt.txt`, `performance_tester/*`, tests that assert Chinese behavior.
- Wake words / exit commands defaults: use English placeholders until chosen (see below).

### 4. Verify
- Grep for remaining CJK; the only expected hits are the "Deferred" items.
- Build manager-api (Maven), run manager-web tests, run the Python tests, start a fresh DB.

## Wake words (decide later)
- Wake words are detected on the ESP32 device. The server only compares the text the device sends
  against `wakeup_words` to play a cached greeting and skip the LLM. A word not in the list still works;
  it goes through the normal LLM path.
- Add them later in `config.yaml` (`wakeup_words`) or via the seeded server parameter in the manager UI.
  Read the exact text from the server log after a real wake-up, then put that in the list.
- The `digital-human` browser client has its own detector (`DEFAULT_WAKE_WORDS` in `js/config/manager.js`);
  that list is independent.
- Vietnamese or English is undecided. Check that the chosen ASR supports the language.

## Deferred / future update: customize for Vietnamese usage
Kept as-is for now; revisit when switching the server to Vietnamese:
- Chinese-only providers: Baidu, Tencent, Aliyun, Volcengine ASR/TTS (`core/providers/asr`, `core/providers/tts`).
  Replace with providers that support Vietnamese, or remove.
- Chinese-only plugins: `get_news_from_chinanews.py`, `get_news_from_newsnow.py`
  (Chinese news sources), `get_weather.py` (default city 广州).
  Replace with Vietnamese/English sources and a local default city.
- ASR language setting (FunASR/SenseVoice) and TTS voice (EdgeTTS): pick Vietnamese or English voices
  and models; update the seeded voice list.
- Wake words and exit commands in Vietnamese; `de/vi/pt_BR` UI locales stay available.
- Prompts (persona, summary, title) currently English; add a Vietnamese reply-language instruction if wanted.
- Home Assistant device examples and other region-specific defaults.

## Status
Done in two local commits (translation + Chinese removal, then a captcha fix). Nothing has been
compiled or run end to end yet; use the checklist below.

## Verification checklist (tick as you test)

### Build and tests
- [ ] manager-api compiles: `mvn -q compile` in `main/manager-api` (never built; edits were string substitutions).
- [ ] manager-api tests pass: `mvn test` (touched: `TimbreServiceImplTest`, `AESUtilsTest`,
      `AgentSnapshotServiceImplTest`, `loginControllerTest`).
- [ ] manager-web: `npm install`, then `npm run build` and the vitest suite (not run: no `node_modules`).
      `npm run check:i18n` and the 9 contract tests already pass.
- [ ] manager-mobile: `npm install`, then type-check/lint/build (not run).
- [ ] xiaozhi-server tests: create `data/.config.yaml`, `pip install pydub`, run
      `python -m pytest tests`. 14 tests (`test_memory`, `test_rag`, `test_stt`, `test_tts`) could not run.

### Fresh-database startup
- [ ] Liquibase applies every changelog on an empty MySQL with no syntax errors (edited by hand, never run).
- [ ] Seed rows look right: `ai_tts_voice` languages are all `English`, agent template is `en`/`English`,
      `end_prompt`, plugin params (`get_weather` default `London`, `news_sources` = `your_news_sources`).
- [ ] `202608061800.sql` (Doubao remark REPLACE removed) applies cleanly.

### Behavior
- [ ] Web UI: login, register, forgot-password; language dropdown shows only en/de/vi/pt_BR; default is English.
- [ ] Wrong graphic captcha shows the error and reloads the image (matches "Graphic verification code";
      only works in English. de/vi/pt_BR messages will not trigger the reload).
- [ ] Mobile app: default English; login links open the English agreement/privacy pages.
- [ ] Device management page no longer has the "device theme generation" button; `/generator` is gone.
- [ ] Server starts; unconfigured values containing `your_` are detected (websocket URL in OTA,
      `mcp_endpoint`, vision URL, api keys) and real values are not mistaken for placeholders.
- [ ] Manager API-driven config: model api keys show masked as `your_<name>` and saving works.
- [ ] Agent role switching (`change_role`): persona names are now English ("English Teacher",
      "Sassy Girlfriend", "Curious Little Boy"); confirm nothing passes the old Chinese names.
- [ ] Chat summary/title generation still works (English prompts).
- [ ] Time/date prompts: weekday and lunar text look sane (lunar is now "Lunar year N, month N, day N").
- [ ] Voiceprint: "Unknown speaker" label is used consistently between server and API.
- [ ] Short-term memory (`mem_local_short`) uses English JSON keys; start with a clean memory store.

### Device and speech
- [ ] ESP32 connects; strings sent to the device (`websocket_server.py`, `ota_handler.py`,
      `vision_handler.py` are now English) do not break the firmware.
- [ ] Read the exact wake-word text your firmware sends from the server log, then set `wakeup_words`
      in `config.yaml` (defaults are `hello`, `hey there`; exit commands `exit`, `quit`, `goodbye`).
- [ ] Wake-up reply: `config/assets/wakeup_words_short.wav` still speaks Chinese; replace it or disable
      `enable_wakeup_words_response_cache`.
- [ ] Pick an English (or Vietnamese) EdgeTTS voice and confirm the FunASR/SenseVoice language setting.
- [ ] `system_error_response` and other fallback replies are English and spoken by a matching voice.

### Cleanup / known leftovers
- [ ] A CJK grep shows only the deferred items above plus binaries/screenshots.
- [ ] Decide on `docs/images/**` screenshots and `manager-mobile/README.md` image filenames (Chinese).
- [ ] Live2D `*_zh` model JSON files (`cdi3`/`physics3`) still hold Chinese parameter labels (display only).
- [ ] `get_weather.py` fallback city is still the Chinese 广州 while `config.yaml` says Guangzhou; unify when customizing.
- [ ] `AgentSnapshotServiceImplTest` still has `locale=zh-CN` in a mock URL (test data only).
- [ ] `manager-mobile/package.json` author name was changed to "Huang Junsen"; confirm or revert.
- [ ] Unrelated untracked dirs `.codegraph/` and `openrouter/` are not committed.
