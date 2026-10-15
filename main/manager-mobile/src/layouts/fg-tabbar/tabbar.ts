/**
 * tabbar state, with storageSync added to ensure the correct tabbar page is shown after a browser refresh
 * Use simple reactive state instead of pinia global state
 */
export const tabbarStore = reactive({
  curIdx: uni.getStorageSync('app-tabbar-index') || 0,
  setCurIdx(idx: number) {
    this.curIdx = idx
    uni.setStorageSync('app-tabbar-index', idx)
  },
})
