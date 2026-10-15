<script setup lang="ts">
import { computed, ref } from 'vue'
import { t } from '@/i18n'
import { toast } from '@/utils/toast'

// Type definitions
interface WiFiNetwork {
  ssid: string
  rssi: number
  authmode: number
  channel: number
}

// Props
interface Props {
  selectedNetwork: WiFiNetwork | null
  password: string
}

const props = defineProps<Props>()

// Reactive data
const configuring = ref(false)

// Computed properties
const canSubmit = computed(() => {
  if (!props.selectedNetwork)
    return false
  if (props.selectedNetwork.authmode > 0 && !props.password)
    return false
  return true
})

// ESP32 connection check
async function checkESP32Connection() {
  try {
    const response = await uni.request({
      url: 'http://192.168.4.1/scan',
      method: 'GET',
      timeout: 3000,
    })
    return response.statusCode === 200
  }
  catch (error) {
    console.log(`${t('deviceConfig.esp32ConnectionCheckFailed')}:`, error)
    return false
  }
}

// Submit provisioning
async function submitConfig() {
  if (!props.selectedNetwork)
    return

  // Check the ESP32 connection
  const connected = await checkESP32Connection()
  if (!connected) {
    toast.error(t('deviceConfig.connectXiaozhiHotspot'))
    return
  }

  configuring.value = true
  console.log(`${t('deviceConfig.startWifiConfig')}:`, props.selectedNetwork.ssid)

  try {
    const response = await uni.request({
      url: 'http://192.168.4.1/submit',
      method: 'POST',
      header: {
        'Content-Type': 'application/json',
      },
      data: {
        ssid: props.selectedNetwork.ssid,
        password: props.selectedNetwork.authmode > 0 ? props.password : '',
      },
      timeout: 15000,
    })

    console.log('WiFi provisioning response:', response)

    if (response.statusCode === 200 && (response.data as any)?.success) {
      toast.success(`${t('deviceConfig.configSuccess')}！${t('deviceConfig.deviceWillConnectTo')} ${props.selectedNetwork.ssid}，${t('deviceConfig.deviceWillRestart')}。${t('deviceConfig.pleaseDisconnectXiaozhiHotspot')}`)
      // The device exits provisioning mode
      setTimeout(() => {
        uni.request({
          url: 'http://192.168.4.1/exit',
          method: 'POST',
          timeout: 15000,
        })
      }, 1500)
    }
    else {
      const errorMsg = (response.data as any)?.error || t('deviceConfig.configFailed')
      toast.error(errorMsg)
    }
  }
  catch (error) {
    console.error(`${t('deviceConfig.wifiConfigFailed')}:`, error)
    toast.error(`${t('deviceConfig.configFailed')}，${t('deviceConfig.pleaseCheckNetworkConnection')}`)
  }
  finally {
    configuring.value = false
  }
}
</script>

<template>
  <view class="wifi-config">
    <!-- Selected network info -->
    <view v-if="props.selectedNetwork" class="selected-network">
      <view class="network-info">
        <view class="network-name">
          {{ t('deviceConfig.selectedNetwork') }}: {{ props.selectedNetwork.ssid }}
        </view>
        <view class="network-details">
          <text class="network-signal">
            {{ t('deviceConfig.signal') }}: {{ props.selectedNetwork.rssi }}dBm
          </text>
          <text class="network-security">
            {{ props.selectedNetwork.authmode === 0 ? t('deviceConfig.openNetwork') : t('deviceConfig.encryptedNetwork') }}
          </text>
        </view>
      </view>
    </view>

    <!-- Provisioning button -->
    <view class="submit-section">
      <wd-button
        type="primary"
        size="large"
        block
        :loading="configuring"
        :disabled="!canSubmit"
        @click="submitConfig"
      >
        {{ configuring ? t('deviceConfig.configuring') : t('deviceConfig.startWifiConfigButton') }}
      </wd-button>
    </view>

    <!-- Usage instructions -->
    <view class="help-section">
      <view class="help-title">
        {{ t('deviceConfig.wifiConfigInstructions') }}
      </view>
      <view class="help-content">
        <text class="help-item">
          1. {{ t('deviceConfig.phoneConnectXiaozhiHotspot') }} (xiaozhi-XXXXXX)
        </text>
        <text class="help-item">
          2. {{ t('deviceConfig.selectTargetWifiNetwork') }}
        </text>
        <text class="help-item">
          3. {{ t('deviceConfig.enterWifiPasswordIfNeeded') }}
        </text>
        <text class="help-item">
          4. {{ t('deviceConfig.clickStartConfigAndWait') }}
        </text>
        <text class="help-tip">
          {{ t('deviceConfig.afterConfigSuccessDeviceWillRestart') }}
        </text>
      </view>
    </view>
  </view>
</template>

<style scoped>
.wifi-config {
  padding: 20rpx 0;
}

.selected-network {
  margin-bottom: 32rpx;
}

.network-info {
  padding: 24rpx;
  background-color: #f0f6ff;
  border: 1rpx solid #336cff;
  border-radius: 16rpx;
}

.network-name {
  font-size: 28rpx;
  font-weight: 600;
  color: #232338;
  margin-bottom: 8rpx;
}

.network-details {
  display: flex;
  gap: 24rpx;
}

.network-signal,
.network-security {
  font-size: 24rpx;
  color: #65686f;
}

.submit-section {
  margin-bottom: 32rpx;
}

.help-section {
  padding: 32rpx 24rpx;
  background-color: #fbfbfb;
  border-radius: 16rpx;
  border: 1rpx solid #eeeeee;
}

.help-title {
  font-size: 28rpx;
  font-weight: 600;
  color: #232338;
  margin-bottom: 20rpx;
}

.help-content {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.help-item {
  font-size: 24rpx;
  color: #65686f;
  line-height: 1.5;
}

.help-tip {
  font-size: 24rpx;
  color: #336cff;
  font-weight: 500;
  margin-top: 8rpx;
}
</style>
