import type { Device, FirmwareType } from './types'
import { http } from '@/http/request/alova'

/**
 * Get device type list
 */
export function getFirmwareTypes() {
  return http.Get<FirmwareType[]>('/admin/dict/data/type/FIRMWARE_TYPE')
}

/**
 * Get bound device list
 * @param agentId agent ID
 */
export function getBindDevices(agentId: string) {
  return http.Get<Device[]>(`/device/bind/${agentId}`, {
    meta: {
      ignoreAuth: false,
      toast: false,
    },
    cacheFor: {
      expire: 0,
    },
  })
}

/**
 * Add device
 * @param agentId agent ID
 * @param code verification code
 */
export function bindDevice(agentId: string, code: string) {
  return http.Post(`/device/bind/${agentId}/${code}`, null)
}

/**
 * Manually add device
 * @param agentId agent ID
 * @param board device type
 * @param appVersion firmware version
 * @param macAddress MAC address
 */
export function bindDeviceManual(data: {
  agentId: string
  board: string
  appVersion: string
  macAddress: string
}) {
  return http.Post('/device/manual-add', data)
}

/**
 * Set the device OTA upgrade switch
 * @param deviceId device ID (MAC address)
 * @param autoUpdate whether to auto-upgrade 0|1
 */
export function updateDeviceAutoUpdate(deviceId: string, autoUpdate: number) {
  return http.Put(`/device/update/${deviceId}`, {
    autoUpdate,
  })
}

/**
 * Unbind device
 * @param deviceId device ID (MAC address)
 */
export function unbindDevice(deviceId: string) {
  return http.Post('/device/unbind', {
    deviceId,
  })
}
