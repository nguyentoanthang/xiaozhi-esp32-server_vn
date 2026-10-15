<route lang="jsonc" type="page">
{
  "layout": "default",
  "style": {
    "navigationStyle": "custom",
    "navigationBarTitleText": "Register"
  }
}
</route>

<script lang="ts" setup>
import { computed, onMounted, ref } from 'vue'
import { register, sendSmsCode } from '@/api/auth'
// Import i18n related features
import { initI18n, t } from '@/i18n'
import { useConfigStore } from '@/store'
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

// Registration form data
interface RegisterData {
  username: string
  password: string
  confirmPassword: string
  captcha: string
  captchaId: string
  areaCode: string
  mobile: string
  mobileCaptcha: string
}

const formData = ref<RegisterData>({
  username: '',
  password: '',
  confirmPassword: '',
  captcha: '',
  captchaId: '',
  areaCode: '+86',
  mobile: '',
  mobileCaptcha: '',
})

// Captcha image
const captchaImage = ref('')
const loading = ref(false)
const smsLoading = ref(false)
const smsCountdown = ref(0)

// Registration method: 'username' | 'mobile'
const registerType = ref<'username' | 'mobile'>('username')

// Get the config store
const configStore = useConfigStore()

// Area code selection related
const showAreaCodeSheet = ref(false)
const selectedAreaCode = ref('+86')
const selectedAreaName = ref('Mainland China')

// Computed property: whether phone number registration is enabled
const enableMobileRegister = computed(() => {
  return configStore.config.enableMobileRegister
})

// Computed property: area code list
const areaCodeList = computed(() => {
  return configStore.config.mobileAreaList || [{ name: 'Mainland China', key: '+86' }]
})

// SM2 public key
const sm2PublicKey = computed(() => {
  return configStore.config.sm2PublicKey
})

// Switch registration method
function toggleRegisterType() {
  registerType.value = registerType.value === 'username' ? 'mobile' : 'username'
  // Clear the input fields
  formData.value.username = ''
  formData.value.mobile = ''
  formData.value.mobileCaptcha = ''
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

// Generate a UUID
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

// Get captcha
async function refreshCaptcha() {
  const uuid = generateUUID()
  formData.value.captchaId = uuid
  captchaImage.value = `${getEnvBaseUrl()}/user/captcha?uuid=${uuid}&t=${Date.now()}`
}

// Send SMS verification code
async function sendSmsVerification() {
  if (!formData.value.mobile) {
    toast.warning(t('register.enterPhone'))
    return
  }
  if (!formData.value.captcha) {
    toast.warning(t('register.enterCode'))
    return
  }

  // Phone number format validation
  const phoneRegex = /^1[3-9]\d{9}$/
  if (!phoneRegex.test(formData.value.mobile)) {
    toast.warning(t('register.enterPhone'))
    return
  }

  try {
    smsLoading.value = true
    await sendSmsCode({
      phone: `${selectedAreaCode.value}${formData.value.mobile}`,
      captcha: formData.value.captcha,
      captchaId: formData.value.captchaId,
    })

    toast.success(t('register.captchaSendSuccess'))

    // Start the countdown
    smsCountdown.value = 60
    const timer = setInterval(() => {
      smsCountdown.value--
      if (smsCountdown.value <= 0) {
        clearInterval(timer)
      }
    }, 1000)
  }
  catch (error: any) {
    // Handle captcha errors - parse the error code from error.message
    if (error.message.includes('Request error [10067]')) {
      toast.warning(t('login.captchaError'))
    }
    // Re-fetch the graphic captcha after sending fails
    refreshCaptcha()
  }
  finally {
    smsLoading.value = false
  }
}

// Register
async function handleRegister() {
  // Form validation
  if (enableMobileRegister.value) {
    // Phone number registration validation
    if (!formData.value.mobile) {
      toast.warning(t('register.enterPhone'))
      return
    }
    // Phone number format validation
    const phoneRegex = /^1[3-9]\d{9}$/
    if (!phoneRegex.test(formData.value.mobile)) {
      toast.warning(t('register.enterPhone'))
      return
    }
    if (!formData.value.mobileCaptcha) {
      toast.warning(t('register.enterCode'))
      return
    }
  }
  else {
    // Username registration validation
    if (!formData.value.username) {
      toast.warning(t('register.enterUsername'))
      return
    }
  }

  if (!formData.value.password) {
    toast.warning(t('register.enterPassword'))
    return
  }

  if (!formData.value.confirmPassword) {
    toast.warning(t('register.confirmPassword'))
    return
  }

  if (formData.value.password !== formData.value.confirmPassword) {
    toast.warning(t('register.confirmPassword'))
    return
  }

  if (!formData.value.captcha) {
    toast.warning(t('register.enterCode'))
    return
  }

  // Check whether the SM2 public key is configured
  if (!sm2PublicKey.value) {
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
      encryptedPassword = sm2Encrypt(sm2PublicKey.value, captchaAndPassword)
    }
    catch (error) {
      console.error('Password encryption failed:', error)
      toast.warning(t('sm2.encryptionFailed'))
      return
    }

    // Build the registration data
    const registerData = {
      username: enableMobileRegister.value ? `${selectedAreaCode.value}${formData.value.mobile}` : formData.value.username,
      password: encryptedPassword,
      captchaId: formData.value.captchaId,
      areaCode: formData.value.areaCode,
      mobile: formData.value.mobile,
      mobileCaptcha: formData.value.mobileCaptcha,
    }

    await register(registerData)
    toast.success(t('message.registerSuccess'))

    // Redirect to the login page
    setTimeout(() => {
      uni.redirectTo({
        url: '/pages/login/index',
      })
    }, 1000)
  }
  catch (error: any) {
    // Handle captcha errors - parse the error code from error.message
    if (error.message.includes('Request error [10067]')) {
      toast.warning(t('login.captchaError'))
    }
    // Handle the phone number already registered error
    else if (error.message.includes('Request error [10070]')) {
      toast.warning(t('message.phoneRegistered'))
    }
    // Re-fetch the captcha after registration fails
    refreshCaptcha()
  }
  finally {
    loading.value = false
  }
}

// Back to login
function goBack() {
  uni.redirectTo({
    url: '/pages/login/index',
  })
}

// Get the captcha when the page loads
onLoad(() => {
  refreshCaptcha()
})

// Make sure the configuration is loaded when the component is mounted
onMounted(async () => {
  if (!configStore.config.name) {
    try {
      await configStore.fetchPublicConfig()
    }
    catch (error) {
      console.error('Failed to get configuration:', error)
    }
  }
  // Initialize i18n
  initI18n()
})
</script>

<template>
  <view class="app-container box-border h-screen w-full" :style="{ paddingTop: `${safeAreaInsets?.top}px` }">
    <view class="header">
      <view class="back-button" @click="goBack">
        <wd-icon name="arrow-left" custom-class="back-icon" />
      </view>
      <view class="logo-section">
        <wd-img :width="80" :height="80" round src="/static/logo.png" class="logo" />
        <text class="welcome-text">
          {{ t('register.pageTitle') }}
        </text>
        <text class="subtitle">
          {{ t('register.createAccount') }}
        </text>
      </view>
    </view>

    <view class="form-container">
      <view class="form">
        <!-- Phone number registration -->
        <template v-if="enableMobileRegister">
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
                  :placeholder="t('register.enterPhone')"
                  type="number"
                  :maxlength="11"
                />
              </view>
            </view>
          </view>
        </template>

        <!-- Username registration -->
        <template v-else>
          <view class="input-group">
            <view class="input-wrapper">
              <wd-input
                v-model="formData.username"
                custom-class="styled-input"
                no-border
                :placeholder="t('register.enterUsername')"
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
              :placeholder="t('register.enterPassword')"
              show-password
              :maxlength="20"
            />
          </view>
        </view>

        <view class="input-group">
          <view class="input-wrapper">
            <wd-input
              v-model="formData.confirmPassword"
              custom-class="styled-input"
              no-border
              :placeholder="t('register.confirmPassword')"
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
              :placeholder="t('register.enterCode')"
              :maxlength="6"
            />
            <view class="captcha-image" @click="refreshCaptcha">
              <image :src="captchaImage" class="captcha-img" />
            </view>
          </view>
        </view>

        <!-- Phone verification code input -->
        <view v-if="enableMobileRegister" class="input-group">
          <view class="input-wrapper sms-wrapper">
            <wd-input
              v-model="formData.mobileCaptcha"
              custom-class="styled-input"
              no-border
              :placeholder="t('register.enterCode')"
              type="number"
              :maxlength="6"
            />
            <wd-button
              :loading="smsLoading"
              :disabled="smsCountdown > 0"
              custom-class="sms-btn"
              @click="sendSmsVerification"
            >
              {{ smsCountdown > 0 ? `${smsCountdown}s` : t('register.getCode') }}
            </wd-button>
          </view>
        </view>

        <view
          class="register-btn"
          type="primary"
          :loading="loading"
          @click="handleRegister"
        >
          {{ loading ? t('register.registering') : t('register.registerButton') }}
        </view>

        <view class="login-hint">
          <text class="hint-text">
            {{ t('register.haveAccount') }}
          </text>
          <text class="login-link" @click="goBack">
            {{ t('register.loginNow') }}
          </text>
        </view>
      </view>
    </view>

    <!-- Area code selection dialog -->
    <wd-action-sheet
      v-model="showAreaCodeSheet"
      :title="t('register.selectCountry')"
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
            {{ t('register.confirm') }}
          </wd-button>
        </view>
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
  position: relative;

  .back-button {
    position: absolute;
    left: 40rpx;
    top: 60rpx;
    width: 60rpx;
    height: 60rpx;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.3s ease;

    &:hover {
      background: rgba(255, 255, 255, 0.3);
    }

    :deep(.back-icon) {
      font-size: 32rpx;
      color: #ffffff;
    }
  }

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
        background: #f8f9fa;
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
          }
        }

        &.sms-wrapper {
          :deep(.sms-btn) {
            margin-left: 20rpx;
            padding: 0 20rpx;
            height: 60rpx;
            border-radius: 8rpx;
            font-size: 24rpx;
            white-space: nowrap;
            min-width: 140rpx;
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

    :deep(.register-btn) {
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

    .login-hint {
      text-align: center;
      margin-bottom: 30rpx;

      .hint-text {
        color: #666666;
        font-size: 26rpx;
        margin-right: 8rpx;
      }

      .login-link {
        color: #667eea;
        font-size: 26rpx;
        font-weight: 500;
        cursor: pointer;

        &:hover {
          text-decoration: underline;
        }
      }
    }

    .register-type-switch {
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
</style>
