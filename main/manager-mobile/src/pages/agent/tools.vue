<route lang="jsonc" type="page">
{
  "layout": "default",
  "style": {
    "navigationBarTitleText": "Edit Functions",
    "navigationStyle": "custom"
  }
}
</route>

<script lang="ts" setup>
import { useMessage } from 'wot-design-uni/components/wd-message-box'
import { getMcpAddress, getMcpTools } from '@/api/agent/agent'
import { t } from '@/i18n'
import { usePluginStore } from '@/store'

const message = useMessage()
const pluginStore = usePluginStore()

const segmentedList = ref<string[]>([t('agent.tools.notSelected'), t('agent.tools.selected')])
const currentSegmented = ref(t('agent.tools.notSelected'))
const notSelectedList = ref<any[]>([])
const selectedList = ref<any[]>([])

// Use computed properties to get data from the store
const allFunctions = computed(() => pluginStore.allFunctions)
const functions = computed(() => pluginStore.currentFunctions)
const agentId = computed(() => pluginStore.currentAgentId)
const mcpAddress = ref('')
const mcpTools = ref<string[]>([])

// Load the MCP address from local storage on initialization
if (uni.getStorageSync(`cachedMcpAddress_${agentId.value}`)) {
  mcpAddress.value = uni.getStorageSync(`cachedMcpAddress_${agentId.value}`)
}

// Parameter editing related
const showParamDialog = ref(false)
const currentFunction = ref<any>(null)
const tempParams = ref<Record<string, any>>({})
const arrayTextCache = ref<Record<string, string>>({})
const jsonTextCache = ref<Record<string, string>>({})

function normalizeFunctionParams(paramInfo: any, fallback: Record<string, any> = {}) {
  if (!paramInfo)
    return { ...fallback }
  if (typeof paramInfo === 'string') {
    try {
      const parsed = JSON.parse(paramInfo)
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : { ...fallback }
    }
    catch {
      return { ...fallback }
    }
  }
  return typeof paramInfo === 'object' && !Array.isArray(paramInfo) ? { ...fallback, ...paramInfo } : { ...fallback }
}

async function mergeFunctions() {
  selectedList.value = functions.value.map((mapping) => {
    const meta = allFunctions.value.find(f => f.id === mapping.pluginId)
    if (!meta) {
      return { id: mapping.pluginId, name: mapping.pluginId, params: normalizeFunctionParams(mapping.paramInfo) }
    }

    return {
      id: mapping.pluginId,
      name: meta.name,
      params: normalizeFunctionParams(mapping.paramInfo, meta.params),
      fieldsMeta: meta.fieldsMeta,
    }
  })

  // Unselected plugins
  notSelectedList.value = allFunctions.value.filter(
    item => !selectedList.value.some(f => f.id === item.id),
  )

  if (agentId.value) {
    // Fetch and display the MCP address first
    try {
      const address = await getMcpAddress(agentId.value)
      mcpAddress.value = address
      // Cache to local storage so it can be shown immediately next time the page is opened
      uni.setStorageSync(`cachedMcpAddress_${agentId.value}`, address)
    }
    catch (error) {
      mcpAddress.value = error
      console.error('Failed to get the MCP address:', error)
    }

    // Fetch the MCP tool list asynchronously without blocking the UI
    try {
      const tools = await getMcpTools(agentId.value)
      mcpTools.value = tools || []
    }
    catch (error) {
      console.error('Failed to get the MCP tool list:', error)
    }
  }
}

// Add a plugin to the selected list
function selectFunction(func: any) {
  // Add to the selected list
  selectedList.value = [...selectedList.value, {
    id: func.id,
    name: func.name,
    params: normalizeFunctionParams(func.params),
    fieldsMeta: func.fieldsMeta,
  }]

  // Remove from the unselected list
  notSelectedList.value = notSelectedList.value.filter(
    item => item.id !== func.id,
  )
}

// Remove a plugin from the selected list
function removeFunction(func: any) {
  // Remove from the selected list
  selectedList.value = selectedList.value.filter(item => item.id !== func.id)

  // Add back to the unselected list
  const originalFunc = allFunctions.value.find(f => f.id === func.id)
  if (originalFunc) {
    notSelectedList.value.push(originalFunc)
  }
}

// Edit plugin parameters
function editFunction(func: any) {
  currentFunction.value = func

  // Use the current function's parameters directly
  tempParams.value = normalizeFunctionParams(func.params)

  // Initialize the text cache
  if (func.fieldsMeta) {
    func.fieldsMeta.forEach((field: any) => {
      if (field.type === 'array') {
        const value = tempParams.value[field.key]
        arrayTextCache.value[field.key] = Array.isArray(value)
          ? value.join('\n')
          : value || ''
      }
      else if (field.type === 'json') {
        const value = tempParams.value[field.key]
        try {
          jsonTextCache.value[field.key] = JSON.stringify(value || {}, null, 2)
        }
        catch {
          jsonTextCache.value[field.key] = '{}'
        }
      }
    })
  }

  showParamDialog.value = true
}

// Handle parameter changes - save in real time
function handleParamChange(key: string, value: any, field: any) {
  tempParams.value[key] = value

  // Update selectedList in real time
  if (currentFunction.value) {
    const index = selectedList.value.findIndex(
      f => f.id === currentFunction.value.id,
    )
    if (index >= 0) {
      selectedList.value[index].params = { ...tempParams.value }
    }
  }
}

// Handle array parameter changes - save in real time
function handleArrayChange(key: string, value: string, field: any) {
  arrayTextCache.value[key] = value
  // Convert to array storage
  const arrayValue = value.split('\n').filter(Boolean)
  tempParams.value[key] = arrayValue

  // Update selectedList in real time
  if (currentFunction.value) {
    const index = selectedList.value.findIndex(
      f => f.id === currentFunction.value.id,
    )
    if (index >= 0) {
      selectedList.value[index].params = { ...tempParams.value }
    }
  }
}

// Handle JSON parameter changes - save in real time
function handleJsonChange(key: string, value: string, field: any) {
  jsonTextCache.value[key] = value
  try {
    const jsonValue = JSON.parse(value)
    tempParams.value[key] = jsonValue

    // Update selectedList in real time
    if (currentFunction.value) {
      const index = selectedList.value.findIndex(
        f => f.id === currentFunction.value.id,
      )
      if (index >= 0) {
        selectedList.value[index].params = { ...tempParams.value }
      }
    }
  }
  catch {
    message.alert(t('agent.tools.jsonFormatError'))
  }
}

// Close the parameter edit dialog
function closeParamEdit() {
  showParamDialog.value = false
  tempParams.value = {}
  arrayTextCache.value = {}
  jsonTextCache.value = {}
}

// Go back to the previous page and update the configuration
function goBack() {
  uni.navigateBack()
}

// Copy the MCP address
function copyMcpAddress() {
  if (!mcpAddress.value) {
    message.alert(t('agent.tools.noMcpAddressToCopy'))
    return
  }

  uni.setClipboardData({
    data: mcpAddress.value,
    showToast: false,
    success: () => {
      message.alert(t('agent.tools.mcpAddressCopied'))
    },
    fail: () => {
      message.alert(t('agent.tools.copyFailed'))
    },
  })
}

// Helper functions for rendering parameter fields
function getFieldDisplayValue(field: any, value: any) {
  if (field.type === 'array') {
    return Array.isArray(value) ? value.join('\n') : value || ''
  }
  return value || ''
}

// Field description
function getFieldRemark(field: any) {
  let description = field.label || ''
  if (field.default) {
    description += `（${t('agent.tools.defaultValue')}：${field.default}）`
  }
  return description
}

// Watch changes to the selected list and update the plugin configuration in real time, to avoid losing the configuration if the user does not click the back button
watch(() => selectedList.value, (newSelectedList) => {
  const finalFunctions = newSelectedList.map(f => ({
    pluginId: f.id,
    paramInfo: normalizeFunctionParams(f.params),
  }))
  pluginStore.updateFunctions(finalFunctions)
})

onMounted(async () => {
  // Get data directly from the store and merge it
  await mergeFunctions()
})
</script>

<template>
  <view class="h-screen flex flex-col bg-[#f5f7fb]">
    <!-- Header navigation -->
    <wd-navbar
      title=""
      safe-area-inset-top
      left-arrow
      :bordered="false"
      @click-left="goBack"
    >
      <template #left>
        <wd-icon name="arrow-left" size="18" />
      </template>
    </wd-navbar>

    <!-- Content area -->
    <scroll-view
      scroll-y
      class="box-border flex-1 bg-transparent px-[20rpx]"
      :style="{ height: 'calc(100vh - 120rpx)' }"
      :scroll-with-animation="true"
    >
      <!-- Built-in plugin area -->
      <view class="mt-[20rpx] flex flex-1 flex-col">
        <view class="text-[32rpx] text-[#333] font-medium">
          {{ t('agent.tools.builtInPlugins') }}
        </view>
        <view
          class="mt-[20rpx] box-border flex flex-1 flex-col rounded-[10rpx] bg-white p-[20rpx]"
        >
          <!-- Segmented control -->
          <wd-segmented
            v-model:value="currentSegmented"
            :options="segmentedList"
          />

          <!-- Plugin list -->
          <view class="mt-[20rpx] flex-1 overflow-hidden">
            <!-- Unselected plugins -->
            <scroll-view
              v-if="currentSegmented === t('agent.tools.notSelected')"
              class="max-h-[600rpx] bg-transparent"
              scroll-y
            >
              <view
                v-if="notSelectedList.length === 0"
                class="h-[400rpx] flex items-center justify-center"
              >
                <wd-status-tip image="content" :tip="t('agent.tools.noMorePlugins')" />
              </view>
              <view v-else class="p-[20rpx] space-y-[20rpx]">
                <view
                  v-for="func in notSelectedList"
                  :key="func.id"
                  class="flex items-center justify-between border border-[#e9ecef] rounded-[10rpx] bg-[#f8f9fa] p-[20rpx]"
                  @click="selectFunction(func)"
                >
                  <view class="flex-1">
                    <view
                      class="mb-[10rpx] text-[30rpx] text-[#333] font-medium"
                    >
                      {{ func.name }}
                    </view>
                    <view class="text-[24rpx] text-[#666]">
                      {{ func.providerCode }}
                    </view>
                  </view>
                  <view
                    class="h-[60rpx] w-[60rpx] flex items-center justify-center rounded-full bg-[#1677ff]"
                  >
                    <text class="text-[36rpx] text-white">
                      +
                    </text>
                  </view>
                </view>
              </view>
            </scroll-view>

            <!-- Selected plugins -->
            <scroll-view v-else class="max-h-[600rpx] bg-transparent" scroll-y>
              <view
                v-if="selectedList.length === 0"
                class="h-[400rpx] flex items-center justify-center"
              >
                <wd-status-tip image="content" :tip="t('agent.tools.pleaseSelectPlugin')" />
              </view>
              <view v-else class="p-[20rpx] space-y-[20rpx]">
                <view
                  v-for="func in selectedList"
                  :key="func.id"
                  class="border border-[#d4edff] rounded-[10rpx] bg-[#f0f7ff] p-[20rpx]"
                >
                  <view class="flex items-center justify-between">
                    <view class="flex-1" @click="editFunction(func)">
                      <view
                        class="mb-[10rpx] text-[30rpx] text-[#333] font-medium"
                      >
                        {{ func.name }}
                      </view>
                      <view class="text-[24rpx] text-[#1677ff]">
                        {{ t('agent.tools.clickToConfigure') }}
                      </view>
                    </view>
                    <view class="flex space-x-[20rpx]">
                      <!-- Configure button -->
                      <view
                        class="h-[60rpx] w-[60rpx] flex items-center justify-center rounded-full bg-[#1677ff]"
                        @click="editFunction(func)"
                      >
                        <text class="text-[24rpx] text-white">
                          ⚙
                        </text>
                      </view>
                      <!-- Remove button -->
                      <view
                        class="h-[60rpx] w-[60rpx] flex items-center justify-center rounded-full bg-[#ff4757]"
                        @click="removeFunction(func)"
                      >
                        <text class="text-[32rpx] text-white">
                          ×
                        </text>
                      </view>
                    </view>
                  </view>
                </view>
              </view>
            </scroll-view>
          </view>
        </view>
      </view>

      <!-- MCP access point area -->
      <view class="mt-[20rpx] flex flex-1 flex-col">
        <view class="text-[32rpx] text-[#333] font-medium">
          {{ t('agent.tools.mcpEndpoint') }}
        </view>
        <view
          class="mt-[20rpx] box-border flex flex-1 flex-col rounded-[10rpx] bg-white p-[20rpx]"
        >
          <view class="flex items-center justify-between text-[24rpx]">
            <input
              v-model="mcpAddress"
              type="text"
              disabled
              class="flex-1 rounded-[10rpx] bg-[#f5f7fb] p-[20rpx]"
            >
            <view
              class="ml-[20rpx] h-[70rpx] flex items-center justify-center rounded-[10rpx] bg-[#1677ff] px-[20rpx] text-[24rpx] text-white"
              @click="copyMcpAddress"
            >
              {{ t('agent.tools.copy') }}
            </view>
          </view>
          <!-- Tool list -->
          <view class="mt-[20rpx] flex-1 overflow-hidden">
            <scroll-view class="max-h-[600rpx] bg-transparent" scroll-y>
              <view
                v-if="mcpTools && mcpTools.length === 0"
                class="h-[400rpx] flex items-center justify-center"
              >
                <wd-status-tip image="content" :tip="t('agent.tools.noTools')" />
              </view>
              <view v-else class="p-[20rpx]">
                <view class="flex flex-wrap">
                  <view
                    v-for="tool in mcpTools"
                    :key="tool"
                    class="mb-[20rpx] mr-[20rpx] rounded-[10rpx] bg-[#f5f7fb] p-[20rpx]"
                  >
                    {{ tool }}
                  </view>
                </view>
              </view>
            </scroll-view>
          </view>
        </view>
      </view>
    </scroll-view>

    <!-- Parameter edit dialog -->
    <wd-action-sheet
      v-model="showParamDialog"
      :title="`${t('agent.tools.parameterConfig')} - ${currentFunction?.name || ''}`"
      custom-header-class="h-[75vh]"
      @close="closeParamEdit"
    >
      <scroll-view
        scroll-y
        class="bg-[#f5f7fb]"
        :style="{ height: 'calc(75vh - 60rpx)' }"
      >
        <view class="p-[30rpx] pb-[40rpx]">
          <!-- No-parameter hint -->
          <view
            v-if="
              !currentFunction?.fieldsMeta
                || currentFunction.fieldsMeta.length === 0
            "
            class="h-[400rpx] flex items-center justify-center"
          >
            <text class="text-[28rpx] text-[#999]">
              {{ currentFunction?.name }} {{ t('agent.tools.noParamsNeeded') }}
            </text>
          </view>

          <!-- Parameter form - card layout -->
          <view v-else class="flex flex-col gap-[24rpx]">
            <view
              v-for="field in currentFunction.fieldsMeta"
              :key="field.key"
              class="border border-[#eeeeee] rounded-[20rpx] bg-white p-[30rpx]"
              style="box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.04);"
            >
              <!-- Field info -->
              <view class="mb-[24rpx]">
                <text class="mb-[8rpx] block text-[32rpx] text-[#232338] font-medium">
                  {{ field.label }}
                </text>
                <text v-if="getFieldRemark(field)" class="block text-[24rpx] text-[#65686f] leading-[1.5]">
                  {{ getFieldRemark(field) }}
                </text>
              </view>

              <!-- Input control -->
              <view>
                <!-- String type -->
                <input
                  v-if="field.type === 'string'"
                  v-model="tempParams[field.key]"
                  class="box-border h-[80rpx] w-full border border-[#eeeeee] rounded-[12rpx] bg-[#f5f7fb] p-[16rpx_20rpx] text-[28rpx] text-[#232338] focus:border-[#336cff] focus:bg-white placeholder:text-[#9d9ea3]"
                  type="text"
                  :placeholder="`${t('agent.tools.pleaseInput')}${field.label}`"
                  @input="
                    handleParamChange(field.key, $event.detail.value, field)
                  "
                >

                <!-- Array type -->
                <view v-else-if="field.type === 'array'">
                  <text class="mb-[16rpx] block text-[24rpx] text-[#65686f]">
                    {{ t('agent.tools.eachLineOneItem') }}
                  </text>
                  <textarea
                    v-model="arrayTextCache[field.key]"
                    class="box-border min-h-[200rpx] w-full border border-[#eeeeee] rounded-[12rpx] bg-[#f5f7fb] p-[20rpx] text-[26rpx] text-[#232338] leading-[1.6] focus:border-[#336cff] focus:bg-white placeholder:text-[#9d9ea3]"
                    :placeholder="`${t('agent.tools.pleaseInput')}${field.label}，${t('agent.tools.eachLineOneItem')}`"
                    @input="
                      handleArrayChange(field.key, $event.detail.value, field)
                    "
                  />
                </view>

                <!-- JSON type -->
                <view v-else-if="field.type === 'json'">
                  <text class="mb-[16rpx] block text-[24rpx] text-[#65686f]">
                    {{ t('agent.tools.pleaseInputValidJson') }}
                  </text>
                  <textarea
                    v-model="jsonTextCache[field.key]"
                    class="box-border min-h-[300rpx] w-full border border-[#eeeeee] rounded-[12rpx] bg-[#f5f7fb] p-[20rpx] text-[26rpx] text-[#232338] leading-[1.6] font-mono focus:border-[#336cff] focus:bg-white placeholder:text-[#9d9ea3]"
                    :placeholder="t('agent.tools.pleaseInputValidJson')"
                    @blur="
                      handleJsonChange(field.key, $event.detail.value, field)
                    "
                  />
                </view>

                <!-- Number type -->
                <input
                  v-else-if="field.type === 'number'"
                  v-model="tempParams[field.key]"
                  class="box-border h-[80rpx] w-full border border-[#eeeeee] rounded-[12rpx] bg-[#f5f7fb] p-[16rpx_20rpx] text-[28rpx] text-[#232338] focus:border-[#336cff] focus:bg-white placeholder:text-[#9d9ea3]"
                  type="number"
                  :placeholder="`${t('agent.tools.pleaseInput')}${field.label}`"
                  @input="
                    handleParamChange(
                      field.key,
                      Number($event.detail.value),
                      field,
                    )
                  "
                >

                <!-- Boolean type -->
                <view
                  v-else-if="field.type === 'boolean' || field.type === 'bool'"
                  class="flex items-center justify-between py-[20rpx]"
                >
                  <view class="flex-1">
                    <text class="mb-[8rpx] block text-[28rpx] text-[#232338]">
                      {{ t('agent.tools.enableFunction') }}
                    </text>
                    <text class="block text-[24rpx] text-[#65686f]">
                      {{ t('agent.tools.toggleFunction') }}
                    </text>
                  </view>
                  <switch
                    :checked="tempParams[field.key]"
                    @change="
                      handleParamChange(field.key, $event.detail.value, field)
                    "
                  />
                </view>

                <!-- Default string type -->
                <input
                  v-else
                  v-model="tempParams[field.key]"
                  class="box-border h-[80rpx] w-full border border-[#eeeeee] rounded-[12rpx] bg-[#f5f7fb] p-[16rpx_20rpx] text-[28rpx] text-[#232338] focus:border-[#336cff] focus:bg-white placeholder:text-[#9d9ea3]"
                  type="text"
                  :placeholder="`${t('agent.tools.pleaseInput')}${field.label}`"
                  @input="
                    handleParamChange(field.key, $event.detail.value, field)
                  "
                >
              </view>
            </view>
          </view>
        </view>
      </scroll-view>
    </wd-action-sheet>
  </view>
</template>

<style scoped lang="scss">
::v-deep .wd-action-sheet__header {
  padding-right: 30rpx;
}
</style>
