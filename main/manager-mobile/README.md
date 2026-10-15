## Control Panel Mobile (manager-mobile)
A cross-platform mobile management client based on uni-app v3 + Vue 3 + Vite. It supports App (Android & iOS) and WeChat Mini Program.

### Platform Compatibility

| H5 | iOS | Android | WeChat Mini Program |
| -- | --- | ------- | ------------------- |
| √  | √   | √       | √                   | 

Note: UI components differ slightly in compatibility across platforms, please refer to the corresponding component library documentation.

### Development Requirements
- Node >= 18
- pnpm >= 7.30 (using the `pnpm@10.x` declared in the project is recommended)
- Optional: HBuilderX (App debugging/packaging), WeChat DevTools (WeChat Mini Program)

### Quick Start
1) Configure environment variables
   - Copy `env/.env.example` to `env/.env.development`
   - Modify the configuration as needed (especially `VITE_SERVER_BASEURL`, `VITE_UNI_APPID`, `VITE_WX_APPID`)

2) Install dependencies

```bash
pnpm i
```

3) Local development (hot reload)
- h5: `pnpm dev:h5`, then check the IP and port shown in the startup log
- WeChat Mini Program: `pnpm dev:mp` or `pnpm dev:mp-weixin`, then import into WeChat DevTools: `dist/dev/mp-weixin`
- App: import `manager-mobile` with HBuilderX, then follow the tutorial below to run it

### Environment Variables and Configuration
The project uses a custom `env` directory for environment files, named following Vite conventions: `.env.development`, `.env.production`, etc.

Key variables (partial):
- VITE_APP_TITLE: application name (written into `manifest.config.ts`)
- VITE_UNI_APPID: uni-app application appid (App)
- VITE_WX_APPID: WeChat Mini Program appid (mp-weixin)
- VITE_FALLBACK_LOCALE: default language, e.g. `zh-Hans`
- VITE_SERVER_BASEURL: server base URL (HTTP request baseURL)
- VITE_DELETE_CONSOLE: whether to remove console at build time (`true`/`false`)
- VITE_SHOW_SOURCEMAP: whether to generate sourcemap (off by default)
- VITE_LOGIN_URL: login page path to redirect to when not logged in (used by the route interceptor)

Example (`env/.env.development`):
```env
VITE_APP_TITLE=Xiaozhi
VITE_FALLBACK_LOCALE=zh-Hans
VITE_UNI_APPID=
VITE_WX_APPID=

VITE_SERVER_BASEURL=http://localhost:8080

VITE_DELETE_CONSOLE=false
VITE_SHOW_SOURCEMAP=false
VITE_LOGIN_URL=/pages/login/index
```

Notes:
- `manifest.config.ts` reads the title, appid, language, and other settings from `env`.

### Important Notes
⚠️ **Settings that must be changed before deployment:**

1. **Application ID configuration**
   - `VITE_UNI_APPID`: create an app in the [DCloud Developer Center](https://dev.dcloud.net.cn/) and obtain the AppID
   - `VITE_WX_APPID`: register a mini program on the [WeChat Official Platform](https://mp.weixin.qq.com/) and obtain the AppID

2. **Server address**
   - `VITE_SERVER_BASEURL`: change to your actual server address

3. **Application info**
   - `VITE_APP_TITLE`: change to your application name
   - Update icon resources such as `src/static/logo.png`

4. **Other settings**
   - Check the application settings in `manifest.config.ts`
   - Modify the tabbar configuration in `src/layouts/fg-tabbar/tabbarList.ts` as needed

### Detailed Guide

#### 1. Get the uni-app AppID
![Generate AppID](../../docs/images/manager-mobile/生成appid.png)
- Copy the generated AppID into the environment variable `VITE_UNI_APPID`.

#### 2. Steps to Run Locally
![Run Locally](../../docs/images/manager-mobile/本地运行.png)

**App local debugging:**
1. Import the `manager-mobile` directory with HBuilderX
2. Re-identify the project
3. Connect a phone or use an emulator for debugging

**Fixing project identification issues:**
![Re-identify Project](../../docs/images/manager-mobile/重新识别项目.png)

If HBuilderX cannot identify the project type correctly:
- Right-click the project root and choose "Re-identify project type"
- Make sure the project is identified as a "uni-app" project

### Routing and Authentication
- The route interceptor plugin `routeInterceptor` is registered in `src/main.ts`.
- Blacklist interception: only pages configured as requiring login are checked (from `getNeedLoginPages` in `@/utils`).
- Login check: based on user info (`useUserStore` of `pinia`); if not logged in, redirects to `VITE_LOGIN_URL` with a parameter to redirect back to the original page.

### Network Requests
- Based on `alova` + `@alova/adapter-uniapp`, with the instance created in `src/http/request/alova.ts`.
- `baseURL` is read from the environment configuration (`getEnvBaseUrl`), and the domain can be switched dynamically through `method.config.meta.domain`.
- Authentication: by default the `Authorization` header is injected from the local `token` (`uni.getStorageSync('token')`); if missing, redirects to login.
- Response: HTTP errors with `statusCode !== 200` and business errors with `code !== 0` are handled uniformly; `401` clears the token and redirects to login.

### Build and Release

**WeChat Mini Program:**
1. Make sure `VITE_WX_APPID` is configured correctly
2. Run `pnpm build:mp`; the output is in `dist/build/mp-weixin`
3. Import the project directory with WeChat DevTools and upload the code
4. Submit for review on the WeChat Official Platform

**Android & iOS App:**

#### 3. App Packaging and Release Steps

**Step 1: Prepare for packaging**
![Packaging Step 1](../../docs/images/manager-mobile/打包发行步骤1.png)

1. Make sure `VITE_UNI_APPID` is configured correctly
2. Run `pnpm build:app`; the output is in `dist/build/app`
3. Import the project directory with HBuilderX
4. In HBuilderX, click "Release" → "Native App - Cloud Packaging"

**Step 2: Configure packaging parameters**
![Packaging Step 2](../../docs/images/manager-mobile/打包发行步骤2.png)

1. **App icon and splash screen**: upload the app icon and splash page images
2. **App version**: set the version number and version name
3. **Signing certificate**:
   - Android: upload the keystore certificate file
   - iOS: configure the developer certificate and provisioning profile
4. **Package name**: set the app package name (Bundle ID)
5. **Package type**: choose a test build or a release build
6. Click "Package" to start the cloud packaging process

**Publish to app stores:**
- **Android**: upload the generated APK file to major Android app markets
- **iOS**: upload the generated IPA file to the App Store through App Store Connect (an Apple developer account is required)

### Conventions and Engineering
- Pages and subpackages: generated by `@uni-helper/vite-plugin-uni-pages` and `pages.config.ts`; the tabbar configuration is in `src/layouts/fg-tabbar/tabbarList.ts`.
- Auto import of components and hooks: see `unplugin-auto-import` and `@uni-helper/vite-plugin-uni-components` in `vite.config.ts`.
- Styles: UnoCSS and `src/style/index.scss`.
- State management: `pinia` + `pinia-plugin-persistedstate`.
- Code style: built-in `eslint`, `husky`, and `lint-staged`; code is formatted automatically before commit (`lint-staged`).

### Common Scripts
```bash
# Development
pnpm dev:mp        # equivalent to dev:mp-weixin

# Build
pnpm build:mp      # equivalent to build:mp-weixin

# Other
pnpm type-check
pnpm lint && pnpm lint:fix
```

### License
MIT
