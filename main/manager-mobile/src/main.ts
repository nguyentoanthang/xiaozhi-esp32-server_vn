import { VueQueryPlugin } from '@tanstack/vue-query'
import { createSSRApp } from 'vue'
import App from './App.vue'
// Import i18n related features
import { initI18n } from './i18n'

import { routeInterceptor } from './router/interceptor'
import store from './store'

import '@/style/index.scss'
import 'virtual:uno.css'

export function createApp() {
  const app = createSSRApp(App)
  app.use(store)
  app.use(routeInterceptor)
  app.use(VueQueryPlugin)

  // Initialize i18n
  initI18n()

  return {
    app,
  }
}
