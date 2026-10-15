import { onLoad } from '@dcloudio/uni-app'
import { useUserStore } from '@/store'
import { needLoginPages as _needLoginPages, getNeedLoginPages } from '@/utils'

const loginRoute = import.meta.env.VITE_LOGIN_URL
const isDev = import.meta.env.DEV
function isLogined() {
  const userStore = useUserStore()
  return !!userStore.userInfo.username
}
// Check whether the current page requires login
export function usePageAuth() {
  onLoad((options) => {
    // Get the current page path
    const pages = getCurrentPages()
    const currentPage = pages[pages.length - 1]
    const currentPath = `/${currentPage.route}`

    // Get the list of pages that require login
    let needLoginPages: string[] = []
    if (isDev) {
      needLoginPages = getNeedLoginPages()
    }
    else {
      needLoginPages = _needLoginPages
    }

    // Check whether the current page requires login
    const isNeedLogin = needLoginPages.includes(currentPath)
    if (!isNeedLogin) {
      return
    }

    const hasLogin = isLogined()
    if (hasLogin) {
      return true
    }

    // Build the redirect URL
    const queryString = Object.entries(options || {})
      .map(([key, value]) => `${key}=${encodeURIComponent(String(value))}`)
      .join('&')

    const currentFullPath = queryString ? `${currentPath}?${queryString}` : currentPath
    const redirectRoute = `${loginRoute}?redirect=${encodeURIComponent(currentFullPath)}`

    // Redirect to the login page
    uni.redirectTo({ url: redirectRoute })
  })
}
