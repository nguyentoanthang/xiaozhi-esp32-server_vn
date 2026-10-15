import type { Ref } from 'vue'
import { defineStore } from 'pinia'
import { ref } from 'vue'

// Supported language types
export type Language = 'en' | 'de' | 'vi' | 'pt_BR'

export interface LangStore {
  currentLang: Ref<Language>
  changeLang: (lang: Language) => void
}

export const useLangStore = defineStore(
  'lang',
  (): LangStore => {
    // Get the language setting from local storage, use the default if absent
    const savedLang = uni.getStorageSync('app_language') as Language | null
    const currentLang = ref<Language>(savedLang || 'en')

    // Switch language
    const changeLang = (lang: Language) => {
      currentLang.value = lang
      // Save the language setting to local storage
      uni.setStorageSync('app_language', lang)
    }

    return {
      currentLang,
      changeLang,
    }
  },
  {
    persist: {
      key: 'lang',
      serializer: {
        serialize: state => JSON.stringify(state.currentLang),
        deserialize: value => ({ currentLang: JSON.parse(value) }),
      },
    },
  },
)
