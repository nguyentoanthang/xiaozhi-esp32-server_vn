<route lang="jsonc" type="page">
{
  "layout": "default",
  "style": {
    "navigationStyle": "custom",
    "navigationBarTitleText": "Login"
  }
}
</route>

<script lang="ts" setup>
import type { LoginData } from '@/api/auth'
import type { Language } from '@/store/lang'
import { computed, onMounted, ref } from 'vue'
import { login } from '@/api/auth'
// Import i18n related features
import { changeLanguage, getSupportedLanguages, initI18n, t } from '@/i18n'
import { useConfigStore, useUserStore } from '@/store'
// Import the SM2 encryption utility
import { getEnvBaseUrl, sm2Encrypt } from '@/utils'
import { toast } from '@/utils/toast'

// Get the distance from the screen edge to the safe area
let safeAreaInsets
let systemInfo

// #ifdef MP-WEIXIN
// WeChat Mini Program uses the new API
systemInfo = uni.getWindowInfo()
safeAreaInsets = systemInfo.safeArea
  ? {
      top: systemInfo.safeArea.top,
      right: systemInfo.windowWidth - systemInfo.safeArea.right,
      bottom: systemInfo.windowHeight - systemInfo.safeArea.bottom,
      left: systemInfo.safeArea.left,
    }
  : null
// #endif

// #ifndef MP-WEIXIN
// Other platforms continue to use the uni API
systemInfo = uni.getSystemInfoSync()
safeAreaInsets = systemInfo.safeAreaInsets
// #endif
// Form data
const formData = ref({
  username: '',
  password: '',
  captcha: '',
  captchaId: '',
  areaCode: '+86',
  mobile: '',
})

// Captcha image
const captchaImage = ref('')
const loading = ref(false)

// Login method: 'username' | 'mobile'
const loginType = ref<'username' | 'mobile'>('username')

// Get the config store
const configStore = useConfigStore()
const userStore = useUserStore()

// Area code selection related
const showAreaCodeSheet = ref(false)
const selectedAreaCode = ref('+86')
const selectedAreaName = ref('Mainland China')

// Computed property: whether phone number login is enabled
const enableMobileLogin = computed(() => {
  return configStore.config.enableMobileRegister
})

// Computed property: area code list
const areaCodeList = computed(() => {
  return configStore.config.mobileAreaList || [{ name: 'Mainland China', key: '+86' }]
})

// Switch login method
function toggleLoginType() {
  loginType.value = loginType.value === 'username' ? 'mobile' : 'username'
  // Clear the input fields
  formData.value.username = ''
  formData.value.mobile = ''
}

// Open the area code selection dialog
function openAreaCodeSheet() {
  showAreaCodeSheet.value = true
}

// Select an area code
function selectAreaCode(item: { name: string, key: string }) {
  selectedAreaCode.value = item.key
  selectedAreaName.value = item.name
  formData.value.areaCode = item.key
  showAreaCodeSheet.value = false
}

// Close the area code selection dialog
function closeAreaCodeSheet() {
  showAreaCodeSheet.value = false
}

// Go to the register page
function goToRegister() {
  uni.navigateTo({
    url: '/pages/register/index',
  })
}

// Go to the forgot password page
function goToForgotPassword() {
  uni.navigateTo({
    url: '/pages/forgot-password/index',
  })
}

// Go to the user agreement
function goToUserAgreement() {
  uni.navigateTo({
    url: '/pages/login/user-agreement-en',
  })
}

// Go to the privacy policy
function goToPrivacyPolicy() {
  uni.navigateTo({
    url: '/pages/login/privacy-policy-en',
  })
}

// Generate a UUID
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0
    const v = c === 'x' ? r : (r & 0x3 | 0x8)
    return v.toString(16)
  })
}

// Go to the server settings page
function goToServerSetting() {
  uni.switchTab({
    url: '/pages/settings/index',
  })
}

// Get captcha
async function refreshCaptcha() {
  const uuid = generateUUID()
  formData.value.captchaId = uuid
  captchaImage.value = `${getEnvBaseUrl()}/user/captcha?uuid=${uuid}&t=${Date.now()}`
}

// Login
async function handleLogin() {
  // Form validation
  if (loginType.value === 'username') {
    if (!formData.value.username) {
      toast.warning(t('login.enterUsername'))
      return
    }
  }
  else {
    if (!formData.value.mobile) {
      toast.warning(t('login.enterPhone'))
      return
    }
    // Phone number format validation
    const phoneRegex = /^1[3-9]\d{9}$/
    if (!phoneRegex.test(formData.value.mobile)) {
      toast.warning(t('login.enterPhone'))
      return
    }
  }
  if (!formData.value.password) {
    toast.warning(t('login.enterPassword'))
    return
  }
  if (!formData.value.captcha) {
    toast.warning(t('login.enterCaptcha'))
    return
  }

  // Check whether the SM2 public key is configured
  const sm2PublicKey = configStore.config.sm2PublicKey
  if (!sm2PublicKey) {
    toast.warning(t('sm2.publicKeyNotConfigured'))
    return
  }

  try {
    loading.value = true

    // Encrypt the password
    let encryptedPassword
    try {
      // Concatenate the captcha and password
      const captchaAndPassword = formData.value.captcha + formData.value.password
      encryptedPassword = sm2Encrypt(sm2PublicKey, captchaAndPassword)
    }
    catch (error) {
      console.error('Password encryption failed:', error)
      toast.warning(t('sm2.encryptionFailed'))
      return
    }

    // Build the login data
    const loginData: LoginData = {
      username: '',
      password: encryptedPassword,
      captchaId: formData.value.captchaId,
    }

    // For phone number login, concatenate the area code and phone number into the username field
    if (loginType.value === 'mobile') {
      loginData.username = `${selectedAreaCode.value}${formData.value.mobile}`
    }
    else {
      loginData.username = formData.value.username
    }

    const response = await login(loginData)
    // Store the token
    uni.setStorageSync('token', JSON.stringify(response))
    await userStore.getUserInfo()

    toast.success(t('message.loginSuccess'))

    // Go to the home page
    setTimeout(() => {
      uni.reLaunch({
        url: '/pages/index/index',
      })
    }, 1000)
  }
  catch (error: any) {
    // Re-fetch the captcha after login fails
    refreshCaptcha()
  }
  finally {
    loading.value = false
  }
}

// Get the captcha when the page loads
onLoad(() => {
  refreshCaptcha()
})

// Language switching related
const showLanguageSheet = ref(false)
const supportedLanguages = getSupportedLanguages()

// Initialize i18n
initI18n()

// Switch language
function handleLanguageChange(lang: Language) {
  changeLanguage(lang)
  showLanguageSheet.value = false
}

// Make sure the configuration is loaded when the component is mounted
onMounted(async () => {
  if (!configStore.config.name) {
    try {
      await configStore.fetchPublicConfig()
    }
    catch (error) {
      console.error(t('login.fetchConfigError'), error)
    }
  }
})
</script>

<template>
  <view class="app-container box-border h-screen w-full" :style="{ paddingTop: `${safeAreaInsets?.top}px` }">
    <view class="header">
      <view class="logo-section">
        <wd-img :width="80" :height="80" round src="/static/logo.png" class="logo" />
        <text class="welcome-text">
          {{ t('login.welcomeBack') }}
        </text>
        <text class="subtitle">
          {{ t('login.pleaseLogin') }}
        </text>
      </view>
    </view>

    <!-- Top-right button group -->
    <view class="top-right-buttons" :style="{ top: `${safeAreaInsets?.top + 10}px` }">
      <!-- Language switch button -->
      <view class="lang-btn" @click="showLanguageSheet = true">
        <text class="lang-text-icon">
          {{ t('login.selectLanguageTip') }}
        </text>
      </view>

      <!-- Server settings button -->
      <view class="server-btn" @click="goToServerSetting">
        <wd-icon name="setting" custom-class="server-icon" />
      </view>
    </view>

    <view class="form-container">
      <view class="form">
        <!-- Phone number login -->
        <template v-if="loginType === 'mobile'">
          <view class="input-group">
            <view class="input-wrapper mobile-wrapper">
              <view class="area-code-selector" @click="openAreaCodeSheet">
                <text class="area-code-text">
                  {{ selectedAreaCode }}
                </text>
                <wd-icon name="arrow-down" custom-class="area-code-arrow" />
              </view>
              <view class="mobile-input-wrapper">
                <wd-input
                  v-model="formData.mobile"
                  custom-class="styled-input"
                  no-border
                  :placeholder="t('login.enterPhone')"
                  type="number"
                  :maxlength="11"
                />
              </view>
            </view>
          </view>
        </template>

        <!-- Username login -->
        <template v-else>
          <view class="input-group">
            <view class="input-wrapper">
              <wd-input
                v-model="formData.username"
                custom-class="styled-input"
                no-border
                :placeholder="t('login.enterUsername')"
              />
            </view>
          </view>
        </template>

        <view class="input-group">
          <view class="input-wrapper">
            <wd-input
              v-model="formData.password"
              custom-class="styled-input"
              no-border
              :placeholder="t('login.enterPassword')"
              clearable
              show-password
              :maxlength="20"
            />
          </view>
        </view>

        <view class="input-group">
          <view class="input-wrapper captcha-wrapper">
            <wd-input
              v-model="formData.captcha"
              custom-class="styled-input"
              no-border
              :placeholder="t('login.enterCaptcha')"
              :maxlength="6"
            />
            <view class="captcha-image" @click="refreshCaptcha">
              <image :src="captchaImage" class="captcha-img" />
            </view>
          </view>
        </view>
        <view
          class="login-btn"
          @click="handleLogin"
        >
          {{ loading ? t('login.loggingIn') : t('login.loginButton') }}
        </view>

        <view class="hint-row">
          <view class="register-hint">
            <text class="register-link" @click="goToRegister">
              {{ t('login.noAccount') }}
            </text>
          </view>

          <view class="forgot-password">
            <text class="forgot-text" @click="goToForgotPassword">
              {{ t('login.forgotPassword') }}
            </text>
          </view>
        </view>

        <view class="policy-links">
          <text class="policy-link" @click="goToUserAgreement">
            {{ t('login.userAgreement') }}
          </text>
          <text class="policy-divider">
            {{ '|' }}
          </text>
          <text class="policy-link" @click="goToPrivacyPolicy">
            {{ t('login.privacyPolicy') }}
          </text>
        </view>

        <!-- Login method switch -->
        <view v-if="enableMobileLogin" class="login-type-switch">
          <view class="switch-tabs">
            <view
              class="switch-tab"
              :class="{ active: loginType === 'username' }"
              @click="toggleLoginType"
            >
              <wd-icon name="user" />
            </view>
            <view
              class="switch-tab"
              :class="{ active: loginType === 'mobile' }"
              @click="toggleLoginType"
            >
              <wd-icon name="phone" />
            </view>
          </view>
        </view>
      </view>
    </view>

    <!-- Area code selection dialog -->
    <wd-action-sheet
      v-model="showAreaCodeSheet"
      :title="t('login.selectCountry')"
      :close-on-click-modal="true"
      @close="closeAreaCodeSheet"
    >
      <view class="area-code-sheet">
        <scroll-view scroll-y class="area-code-list">
          <view
            v-for="item in areaCodeList"
            :key="item.key"
            class="area-code-item"
            :class="{ selected: selectedAreaCode === item.key }"
            @click="selectAreaCode(item)"
          >
            <view class="area-info">
              <text class="area-name">
                {{ item.name }}
              </text>
              <text class="area-code">
                {{ item.key }}
              </text>
            </view>
            <wd-icon
              v-if="selectedAreaCode === item.key"
              name="check"
              custom-class="check-icon"
            />
          </view>
        </scroll-view>
        <view class="sheet-footer">
          <wd-button
            type="primary"
            custom-class="confirm-btn"
            @click="closeAreaCodeSheet"
          >
            {{ t('login.confirm') }}
          </wd-button>
        </view>
      </view>
    </wd-action-sheet>

    <!-- Language selection dialog -->
    <wd-action-sheet
      v-model="showLanguageSheet"
      :title="t('login.selectLanguage')"
      :close-on-click-modal="true"
    >
      <view class="language-sheet">
        <scroll-view scroll-y class="language-list">
          <view
            v-for="lang in supportedLanguages"
            :key="lang.code"
            class="language-item"
            @click="handleLanguageChange(lang.code)"
          >
            <text class="language-name">
              {{ lang.name }}
            </text>
          </view>
        </scroll-view>
      </view>
    </wd-action-sheet>
  </view>
</template>

<style lang="scss" scoped>
.app-container {
  background: linear-gradient(145deg, #f5f8fd, #6baaff, #9ebbfc, #f5f8fd);
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  min-height: 100vh;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, rgba(255, 255, 255, 0.1) 0%, transparent 70%);
    animation: float 6s ease-in-out infinite;
  }
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(-20px) rotate(180deg);
  }
}

.header {
  flex: 0 0 auto;
  min-height: 280rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 15% 0 40rpx 0;

  .logo-section {
    text-align: center;

    .logo {
      margin-bottom: 20rpx;
      box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
    }

    .welcome-text {
      display: block;
      color: #ffffff;
      font-size: 40rpx;
      font-weight: 600;
      margin-bottom: 12rpx;
      text-shadow: 0 2rpx 4rpx rgba(0, 0, 0, 0.1);
    }

    .subtitle {
      display: block;
      color: rgba(255, 255, 255, 0.8);
      font-size: 26rpx;
      font-weight: 400;
    }
  }
}

.form-container {
  padding: 0 40rpx 40rpx 40rpx;
  flex: 1;
  display: flex;
  align-items: flex-start;

  .form {
    width: 100%;
    background: rgba(255, 255, 255, 0.95);
    border-radius: 24rpx;
    padding: 40rpx 30rpx 30rpx 30rpx;
    backdrop-filter: blur(10rpx);
    box-shadow: 0 20rpx 60rpx rgba(0, 0, 0, 0.1);
    border: 1rpx solid rgba(255, 255, 255, 0.2);
    max-height: calc(100vh - 350rpx);
    overflow-y: auto;

    .input-group {
      margin-bottom: 24rpx;

      .input-wrapper {
        position: relative;
        border-radius: 16rpx;
        padding: 20rpx 16rpx;
        border: 2rpx solid #e9ecef;
        transition: all 0.3s ease;
        display: flex;
        align-items: center;

        &:focus-within {
          border-color: #667eea;
          background: #ffffff;
          box-shadow: 0 0 0 6rpx rgba(102, 126, 234, 0.1);
        }

        &.captcha-wrapper {
          .captcha-image {
            margin-left: 20rpx;
            width: 150rpx;
            height: 60rpx;
            border-radius: 8rpx;
            overflow: hidden;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #e9ecef;
            border: 1rpx solid #ddd;

            .captcha-img {
              width: 100%;
              height: 100%;
            }

            .captcha-loading {
              font-size: 20rpx;
              color: #999;
            }
          }
        }

        &.mobile-wrapper {
          padding: 0;
          background: transparent;
          border: none;
          display: flex;
          gap: 20rpx;

          .area-code-selector {
            flex: 0 0 160rpx;
            background: #f8f9fa;
            border-radius: 16rpx;
            padding: 20rpx 16rpx;
            border: 2rpx solid #e9ecef;
            height: 45rpx;
            display: flex;
            align-items: center;
            justify-content: space-between;
            cursor: pointer;
            transition: all 0.3s ease;

            &:hover {
              border-color: #667eea;
              background: #ffffff;
              box-shadow: 0 0 0 6rpx rgba(102, 126, 234, 0.1);
            }

            .area-code-text {
              font-size: 28rpx;
              color: #333333;
              font-weight: 500;
            }

            :deep(.area-code-arrow) {
              font-size: 24rpx;
              color: #999999;
              transition: transform 0.3s ease;
            }
          }

          .mobile-input-wrapper {
            flex: 1;
            background: #f8f9fa;
            border-radius: 16rpx;
            padding: 20rpx 16rpx;
            border: 2rpx solid #e9ecef;
            transition: all 0.3s ease;

            &:focus-within {
              border-color: #667eea;
              background: #ffffff;
              box-shadow: 0 0 0 6rpx rgba(102, 126, 234, 0.1);
            }
          }
        }

        :deep(.styled-input) {
          background: transparent !important;
          border: none !important;
          outline: none !important;
          font-size: 32rpx;
          color: #333333;
          flex: 1;

          &::placeholder {
            color: #999999;
            font-size: 28rpx;
          }
        }
      }
    }

    .hint-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30rpx;
    }

    .policy-links {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 20rpx;
      margin-bottom: 30rpx;

      .policy-link {
        color: #667eea;
        font-size: 26rpx;
        cursor: pointer;

        &:hover {
          text-decoration: underline;
        }
      }

      .policy-divider {
        color: #999999;
        font-size: 26rpx;
      }
    }

    .forgot-password {
      .forgot-text {
        color: #667eea;
        font-size: 26rpx;
        cursor: pointer;

        &:hover {
          text-decoration: underline;
        }
      }
    }

    .login-btn {
      width: 100%;
      height: 80rpx;
      border: none;
      border-radius: 16rpx;
      font-size: 30rpx;
      font-weight: 600;
      color: #ffffff;
      margin-bottom: 30rpx;
      box-shadow: 0 8rpx 24rpx rgba(102, 126, 234, 0.3);
      transition: all 0.3s ease;
      background-color: var(--wot-button-primary-bg-color, var(--wot-color-theme, #4d80f0));
      text-align: center;
      line-height: 80rpx;
      &:active {
        transform: translateY(2rpx);
        box-shadow: 0 4rpx 12rpx rgba(102, 126, 234, 0.3);
      }

      &:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
    }

    .register-hint {
      .register-link {
        color: #667eea;
        font-size: 26rpx;
        font-weight: 500;
        cursor: pointer;
        // text-decoration: underline;
        // &:hover {
        //   text-decoration: underline;
        // }
      }
    }

    .login-type-switch {
      margin-top: 20rpx;
      text-align: center;

      .switch-tabs {
        display: flex;
        justify-content: center;
        gap: 60rpx;
        margin-bottom: 20rpx;

        .switch-tab {
          width: 60rpx;
          height: 60rpx;
          border-radius: 50%;
          background: #f0f0f0;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.3s ease;
          border: 2rpx solid transparent;

          &.active {
            background: #667eea;
            color: #ffffff;
            border-color: #667eea;
            box-shadow: 0 4rpx 12rpx rgba(102, 126, 234, 0.3);
          }

          :deep(.wd-icon) {
            font-size: 24rpx;
          }
        }
      }

      .switch-hint {
        font-size: 24rpx;
        color: #666666;
      }
    }
  }
}

// Area code selection dialog styles
.area-code-sheet {
  background: #ffffff;
  border-radius: 24rpx 24rpx 0 0;
  overflow: hidden;

  .sheet-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 40rpx 40rpx 20rpx 40rpx;
    border-bottom: 1rpx solid #f0f0f0;

    .sheet-title {
      font-size: 36rpx;
      font-weight: 600;
      color: #333333;
    }

    :deep(.close-icon) {
      font-size: 32rpx;
      color: #999999;
      cursor: pointer;
      padding: 10rpx;

      &:hover {
        color: #333333;
      }
    }
  }

  .area-code-list {
    max-height: 60vh;
    padding: 0 40rpx;

    .area-code-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 32rpx 0;
      border-bottom: 1rpx solid #f8f9fa;
      cursor: pointer;
      transition: background-color 0.3s ease;

      &:hover {
        background-color: #f8f9fa;
      }

      &.selected {
        background-color: rgba(102, 126, 234, 0.05);

        .area-name {
          color: #667eea;
          font-weight: 500;
        }

        .area-code {
          color: #667eea;
        }
      }

      .area-info {
        display: flex;
        flex-direction: column;
        gap: 8rpx;

        .area-name {
          font-size: 32rpx;
          color: #333333;
        }

        .area-code {
          font-size: 28rpx;
          color: #666666;
        }
      }

      :deep(.check-icon) {
        font-size: 32rpx;
        color: #667eea;
      }
    }
  }

  .sheet-footer {
    padding: 30rpx 40rpx 40rpx 40rpx;
    border-top: 1rpx solid #f0f0f0;

    :deep(.confirm-btn) {
      width: 100%;
      height: 88rpx;
      border-radius: 16rpx;
      font-size: 32rpx;
      font-weight: 600;
    }
  }
}
// Top-right button group
.top-right-buttons {
  position: absolute;
  right: 20rpx;
  display: flex;
  gap: 20rpx;
  z-index: 999;
}

// Language switch button
.lang-btn {
  width: 48rpx;
  height: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 24rpx;
  box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.2);

  &:active {
    transform: scale(0.95);
  }

  .lang-text-icon {
    font-size: 18rpx;
    color: #ffffff;
  }

  &:hover {
    background: rgba(255, 255, 255, 0.25);
  }
}

// Server settings button
.server-btn {
  width: 48rpx;
  height: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 24rpx;
  box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.2);

  &:active {
    transform: scale(0.95);
  }

  .server-icon {
    font-size: 28rpx;
    color: #ffffff;
  }

  &:hover {
    background: rgba(255, 255, 255, 0.25);
  }
}

// Language selection dialog styles
.language-sheet {
  background: #ffffff;
  border-radius: 24rpx 24rpx 0 0;
  overflow: hidden;

  .language-list {
    max-height: 60vh;
    padding: 0 40rpx;

    .language-item {
      display: flex;
      align-items: center;
      padding: 32rpx 0;
      border-bottom: 1rpx solid #f8f9fa;
      cursor: pointer;
      transition: background-color 0.3s ease;

      &:hover {
        background-color: #f8f9fa;
      }

      &:last-child {
        border-bottom: none;
      }

      .language-name {
        font-size: 32rpx;
        color: #333333;
      }
    }
  }
}
</style>
