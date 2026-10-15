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
Done in one commit. Not verified: Java was never compiled (no Maven), SQL never run against MySQL, web vitest and mobile type-check not run.
