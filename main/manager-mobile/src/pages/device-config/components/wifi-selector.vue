<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useToast } from 'wot-design-uni/components/wd-toast'
import { t } from '@/i18n'

// Type definitions
interface WiFiNetwork {
  ssid: string
  rssi: number
  authmode: number
  channel: number
}

// Props
interface Props {
  autoConnect?: boolean // Whether to auto-detect the ESP32 connection
}

const props = withDefaults(defineProps<Props>(), {
  autoConnect: true,
})

// Emits
const emit = defineEmits<{
  'network-selected': [network: WiFiNetwork | null, password: string]
  'connection-status': [connected: boolean]
}>()

// Toast instance
const toast = useToast()

// Reactive data
const isConnectedToESP32 = ref(false)
const checkingConnection = ref(false)
const scanning = ref(false)
const wifiNetworks = ref<WiFiNetwork[]>([])
const selectedNetwork = ref<WiFiNetwork | null>(null)
const password = ref('')
const selectorExpanded = ref(false)

// Computed properties
const networkDisplayText = computed(() => {
  if (!selectedNetwork.value)
    return t('deviceConfig.selectWifiNetwork')
  return selectedNetwork.value.ssid
})

// Check the xiaozhi connection state
async function checkESP32Connection() {
  checkingConnection.value = true
  try {
    const response = await uni.request({
      url: 'http://192.168.4.1/scan',
      method: 'GET',
      timeout: 3000,
    })
    isConnectedToESP32.value = response.statusCode === 200
    emit('connection-status', isConnectedToESP32.value)
    console.log(`${t('deviceConfig.xiaozhi')} connection state:`, isConnectedToESP32.value)
  }
  catch (error) {
    isConnectedToESP32.value = false
    emit('connection-status', false)
    console.log('xiaozhi connection check failed:', error)
  }
  finally {
    checkingConnection.value = false
  }
}

// Scan WiFi networks
async function scanWifi() {
  if (!isConnectedToESP32.value) {
    toast.error(t('deviceConfig.connectXiaozhiHotspot'))
    return
  }

  scanning.value = true
  console.log('Starting WiFi network scan')

  try {
    const response = await uni.request({
      url: 'http://192.168.4.1/scan',
      method: 'GET',
      timeout: 10000,
    })

    console.log(`${t('deviceConfig.wifiScanResponse')}:`, response)

    if (response.statusCode === 200 && response.data) {
      const data = response.data as any
      if (data.success && Array.isArray(data.networks)) {
        wifiNetworks.value = data.networks
        console.log(`${t('deviceConfig.scanSuccess')}, found${data.networks.length} ${t('deviceConfig.networks')}`)
      }
      else if (data.aps && Array.isArray(data.aps)) {
        // Compatible with the { data: { support_5g, aps } } format
        wifiNetworks.value = data.aps.map((item: any) => ({
          ssid: item.ssid,
          rssi: item.rssi,
          authmode: item.authmode,
          channel: item.channel || 0,
        }))
        console.log(`${t('deviceConfig.scanSuccess')}, found${data.aps.length} ${t('deviceConfig.networks')}`)
      }
      else if (Array.isArray(response.data)) {
        // Compatible with the old format
        wifiNetworks.value = response.data.map((item: any) => ({
          ssid: item.ssid,
          rssi: item.rssi,
          authmode: item.authmode,
          channel: item.channel || 0,
        }))
      }
      else {
        throw new TypeError('Unexpected format returned by the scan API')
      }
    }
    else {
      throw new Error(`HTTP ${response.statusCode}`)
    }
  }
  catch (error) {
    console.error(`${t('deviceConfig.wifiScanFailed')}:`, error)
    toast.error(t('deviceConfig.scanFailedCheckConnection'))
  }
  finally {
    scanning.value = false
  }
}

// Show the network selector
async function showNetworkSelector() {
  // Detect the xiaozhi connection state in real time
  await checkESP32Connection()

  if (!isConnectedToESP32.value) {
    toast.error(t('deviceConfig.connectXiaozhiHotspot'))
    return
  }

  selectorExpanded.value = true

  // If there is no network list yet, scan automatically
  if (wifiNetworks.value.length === 0) {
    scanWifi()
  }
}

// Select a network
function selectNetwork(network: WiFiNetwork) {
  selectedNetwork.value = network
  password.value = ''
  selectorExpanded.value = false
  console.log('Selected network:', network.ssid)

  // Notify the parent component
  emit('network-selected', network, '')
}

// Notify the parent component when the password changes
function onPasswordChange() {
  emit('network-selected', selectedNetwork.value, password.value)
}

// Get the currently selected network and password
function getSelectedNetworkInfo() {
  return {
    network: selectedNetwork.value,
    password: password.value,
  }
}

// Reset the selection
function reset() {
  selectedNetwork.value = null
  password.value = ''
  wifiNetworks.value = []
  selectorExpanded.value = false
  emit('network-selected', null, '')
}

// Get the signal strength description
function getSignalStrength(rssi: number): string {
  if (rssi >= -50)
    return t('deviceConfig.signalStrong')
  if (rssi >= -60)
    return t('deviceConfig.signalGood')
  if (rssi >= -70)
    return t('deviceConfig.signalFair')
  return t('deviceConfig.signalWeak')
}

// Get the signal strength color
function getSignalColor(rssi: number): string {
  if (rssi >= -50)
    return '#52c41a'
  if (rssi >= -60)
    return '#73d13d'
  if (rssi >= -70)
    return '#faad14'
  return '#ff4d4f'
}

// Expose methods to the parent component
defineExpose({
  checkESP32Connection,
  scanWifi,
  getSelectedNetworkInfo,
  reset,
})

// Lifecycle
onMounted(() => {
  if (props.autoConnect) {
    checkESP32Connection()
  }
})
</script>

<template>
  <view class="wifi-selector">
    <!-- Xiaozhi connection state -->
    <view v-if="props.autoConnect" class="connection-status">
      <view v-if="!isConnectedToESP32" class="status-warning">
        <view class="status-content">
          <text class="warning-text">
            {{ t('deviceConfig.connectXiaozhiHotspot') }} (xiaozhi-XXXXXX)
          </text>
          <wd-button
            size="small"
            type="primary"
            :loading="checkingConnection"
            @click="checkESP32Connection"
          >
            {{ checkingConnection ? t('deviceConfig.checking') : t('deviceConfig.reCheck') }}
          </wd-button>
        </view>
      </view>
      <view v-else class="status-success">
        <view class="status-content">
          <text class="success-text">
            {{ t('deviceConfig.connectedXiaozhiHotspot') }}
          </text>
          <wd-button
            size="small"
            :loading="checkingConnection"
            @click="checkESP32Connection"
          >
            {{ checkingConnection ? t('deviceConfig.checking') : t('deviceConfig.refreshStatus') }}
          </wd-button>
        </view>
      </view>
    </view>

    <!-- WiFi network selector -->
    <view class="network-selector">
      <view class="selector-item" @click="showNetworkSelector">
        <text class="selector-label">
          {{ t('deviceConfig.wifiNetwork') }}
        </text>
        <text class="selector-value">
          {{ networkDisplayText }}
        </text>
        <wd-icon name="arrow-right" custom-class="arrow-icon" />
      </view>
    </view>

    <!-- Expanded network list -->
    <view v-if="selectorExpanded" class="network-list-overlay">
      <view class="network-list-container">
        <view class="list-header">
          <text class="list-title">
            {{ t('deviceConfig.selectWifiNetwork') }}
          </text>
          <view class="list-actions">
            <wd-button
              type="primary"
              size="small"
              :loading="scanning"
              @click="scanWifi"
            >
              {{ scanning ? t('deviceConfig.scanning') : t('deviceConfig.refreshScan') }}
            </wd-button>
            <wd-button
              size="small"
              @click="selectorExpanded = false"
            >
              {{ t('deviceConfig.cancel') }}
            </wd-button>
          </view>
        </view>

        <view class="network-list">
          <view v-if="wifiNetworks.length === 0 && !scanning" class="empty-state">
            <text class="empty-text">
              {{ t('deviceConfig.noWifiNetworks') }}
            </text>
            <text class="empty-tip">
              {{ t('deviceConfig.clickRefreshScan') }}
            </text>
          </view>

          <view v-else class="wifi-list">
            <view
              v-for="network in wifiNetworks"
              :key="network.ssid"
              class="wifi-item"
              @click="selectNetwork(network)"
            >
              <view class="wifi-info">
                <view class="wifi-name">
                  {{ network.ssid }}
                </view>
                <view class="wifi-details">
                  <text class="wifi-signal">
                    {{ t('deviceConfig.signal') }}: {{ network.rssi }}dBm
                  </text>
                  <text class="wifi-channel">
                    {{ t('deviceConfig.channel') }}: {{ network.channel }}
                  </text>
                </view>
              </view>
              <view class="wifi-security">
                <text class="security-icon">
                  {{ network.authmode === 0 ? t('deviceConfig.open') : t('deviceConfig.encryptedNetwork') }}
                </text>
              </view>
            </view>
          </view>
        </view>
      </view>
    </view>

    <!-- Password input -->
    <view v-if="selectedNetwork && selectedNetwork.authmode > 0" class="password-section">
      <view class="password-item">
        <text class="password-label">
          {{ t('deviceConfig.wifiPassword') }}
        </text>
        <wd-input
          v-model="password"
          :placeholder="t('deviceConfig.enterWifiPassword')"
          show-password
          clearable
          @input="onPasswordChange"
        />
      </view>
    </view>
  </view>
</template>

<style scoped>
.wifi-selector {
  width: 100%;
}

.connection-status {
  margin-bottom: 24rpx;
}

.status-warning {
  padding: 24rpx;
  background-color: #fff3cd;
  border: 1rpx solid #ffeaa7;
  border-radius: 16rpx;
}

.status-success {
  padding: 24rpx;
  background-color: #d4edda;
  border: 1rpx solid #c3e6cb;
  border-radius: 16rpx;
}

.status-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.warning-text {
  color: #856404;
  font-size: 28rpx;
}

.success-text {
  color: #155724;
  font-size: 28rpx;
}

.network-selector {
  margin-bottom: 24rpx;
}

.selector-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20rpx;
  background: #f5f7fb;
  border-radius: 12rpx;
  border: 1rpx solid #eeeeee;
  cursor: pointer;
  transition: all 0.3s ease;
}

.selector-item:active {
  background: #eef3ff;
  border-color: #336cff;
}

.selector-label {
  font-size: 28rpx;
  color: #232338;
  font-weight: 500;
}

.selector-value {
  flex: 1;
  text-align: right;
  font-size: 26rpx;
  color: #65686f;
  margin: 0 16rpx;
}

:deep(.arrow-icon) {
  font-size: 20rpx;
  color: #9d9ea3;
}

.network-list-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 1000;
  display: flex;
  align-items: flex-end;
}

.network-list-container {
  width: 100%;
  max-height: 70vh;
  background-color: #ffffff;
  border-radius: 20rpx 20rpx 0 0;
  padding: 32rpx;
  box-sizing: border-box;
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24rpx;
  padding-bottom: 16rpx;
  border-bottom: 1rpx solid #eeeeee;
}

.list-title {
  font-size: 32rpx;
  font-weight: 600;
  color: #232338;
}

.list-actions {
  display: flex;
  gap: 16rpx;
}

.network-list {
  max-height: 50vh;
  overflow-y: auto;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 80rpx 20rpx;
  background-color: #fbfbfb;
  border-radius: 16rpx;
  border: 1rpx solid #eeeeee;
}

.empty-text {
  font-size: 32rpx;
  color: #65686f;
  margin-bottom: 16rpx;
}

.empty-tip {
  font-size: 24rpx;
  color: #9d9ea3;
}

.wifi-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.wifi-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 32rpx 24rpx;
  background-color: #fbfbfb;
  border: 2rpx solid #eeeeee;
  border-radius: 16rpx;
  transition: all 0.3s ease;
  cursor: pointer;
}

.wifi-item:active {
  transform: scale(0.98);
  background-color: #f0f6ff;
  border-color: #336cff;
}

.wifi-info {
  flex: 1;
}

.wifi-name {
  font-size: 32rpx;
  font-weight: 600;
  color: #232338;
  margin-bottom: 8rpx;
}

.wifi-details {
  display: flex;
  gap: 24rpx;
}

.wifi-signal,
.wifi-channel {
  font-size: 24rpx;
  color: #65686f;
}

.security-icon {
  font-size: 24rpx;
  color: #65686f;
  margin-left: 20rpx;
}

.password-section {
  margin-top: 24rpx;
}

.password-item {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.password-label {
  font-size: 28rpx;
  color: #232338;
  font-weight: 500;
}
</style>
