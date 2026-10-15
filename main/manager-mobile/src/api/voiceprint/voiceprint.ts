import type {
  ChatHistory,
  CreateSpeakerData,
  VoicePrint,
} from './types'
import { http } from '@/http/request/alova'

// Get voiceprint list
export function getVoicePrintList(agentId: string) {
  return http.Get<VoicePrint[]>(`/agent/voice-print/list/${agentId}`, {
    meta: {
      ignoreAuth: false,
      toast: false,
    },
    cacheFor: {
      expire: 0,
    },
  })
}

// Get voice conversation records (used to select voiceprint vectors)
export function getChatHistory(agentId: string) {
  return http.Get<ChatHistory[]>(`/agent/${agentId}/chat-history/user`, {
    meta: {
      ignoreAuth: false,
      toast: false,
    },
    cacheFor: {
      expire: 0,
    },
  })
}

// Add speaker
export function createVoicePrint(data: CreateSpeakerData) {
  return http.Post<null>('/agent/voice-print', data, {
    meta: {
      ignoreAuth: false,
      toast: true,
    },
  })
}

// Delete voiceprint
export function deleteVoicePrint(id: string) {
  return http.Delete<null>(`/agent/voice-print/${id}`, {
    meta: {
      ignoreAuth: false,
      toast: true,
    },
  })
}

// Update voiceprint info
export function updateVoicePrint(data: VoicePrint) {
  return http.Put<null>('/agent/voice-print', data, {
    meta: {
      ignoreAuth: false,
      toast: true,
    },
  })
}

// Get audio download ID
export function getAudioDownloadId(audioId: string) {
  return http.Post<string>(`/agent/audio/${audioId}`, {}, {
    meta: {
      ignoreAuth: false,
      toast: false,
    },
  })
}
