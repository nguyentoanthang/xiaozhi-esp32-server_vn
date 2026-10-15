import { ref } from 'vue'
import { getEnvBaseUploadUrl } from '@/utils'

const VITE_UPLOAD_BASEURL = `${getEnvBaseUploadUrl()}`

type TfileType = 'image' | 'file'
type TImage = 'png' | 'jpg' | 'jpeg' | 'webp' | '*'
type TFile = 'doc' | 'docx' | 'ppt' | 'zip' | 'xls' | 'xlsx' | 'txt' | TImage

interface TOptions<T extends TfileType> {
  formData?: Record<string, any>
  maxSize?: number
  accept?: T extends 'image' ? TImage[] : TFile[]
  fileType?: T
  success?: (params: any) => void
  error?: (err: any) => void
}

export default function useUpload<T extends TfileType>(options: TOptions<T> = {} as TOptions<T>) {
  const {
    formData = {},
    maxSize = 5 * 1024 * 1024,
    accept = ['*'],
    fileType = 'image',
    success,
    error: onError,
  } = options

  const loading = ref(false)
  const error = ref<Error | null>(null)
  const data = ref<any>(null)

  const handleFileChoose = ({ tempFilePath, size }: { tempFilePath: string, size: number }) => {
    if (size > maxSize) {
      uni.showToast({
        title: `File size cannot exceed ${maxSize / 1024 / 1024}MB`,
        icon: 'none',
      })
      return
    }

    // const fileExtension = file?.tempFiles?.name?.split('.').pop()?.toLowerCase()
    // const isTypeValid = accept.some((type) => type === '*' || type.toLowerCase() === fileExtension)

    // if (!isTypeValid) {
    //   uni.showToast({
    //     title: `Only ${accept.join(', ')} formats are supported`,
    //     icon: 'none',
    //   })
    //   return
    // }

    loading.value = true
    uploadFile({
      tempFilePath,
      formData,
      onSuccess: (res) => {
        const { data: _data } = JSON.parse(res)
        data.value = _data
        // console.log('upload succeeded', res)
        success?.(_data)
      },
      onError: (err) => {
        error.value = err
        onError?.(err)
      },
      onComplete: () => {
        loading.value = false
      },
    })
  }

  const run = () => {
    // Since base library 2.21.0, WeChat Mini Program no longer maintains wx.chooseImage, please use uni.chooseMedia instead.
    // After October 17, 2023, WeChat Mini Program requires a privacy agreement to be configured to use this API
    const chooseFileOptions = {
      count: 1,
      success: (res: any) => {
        console.log('File selected successfully:', res)
        // In mini programs res:{errMsg: "chooseImage:ok", tempFiles: [{fileType: "image", size: 48976, tempFilePath: "http://tmp/5iG1WpIxTaJf3ece38692a337dc06df7eb69ecb49c6b.jpeg"}]}
        // In h5 res:{errMsg: "chooseImage:ok", tempFilePaths: "blob:http://localhost:9000/f74ab6b8-a14d-4cb6-a10d-fcf4511a0de5", tempFiles: [File]}
        // The h5 File has the following fields:{name: "girl.jpeg", size: 48976, type: "image/jpeg"}
        // In App res:{errMsg: "chooseImage:ok", tempFilePaths: "file:///Users/feige/xxx/gallery/1522437259-compressed-IMG_0006.jpg", tempFiles: [File]}
        // The App File has the following fields:{path: "file:///Users/feige/xxx/gallery/1522437259-compressed-IMG_0006.jpg", size: 48976}
        let tempFilePath = ''
        let size = 0
        // #ifdef MP-WEIXIN
        tempFilePath = res.tempFiles[0].tempFilePath
        size = res.tempFiles[0].size
        // #endif
        // #ifndef MP-WEIXIN
        tempFilePath = res.tempFilePaths[0]
        size = res.tempFiles[0].size
        // #endif
        handleFileChoose({ tempFilePath, size })
      },
      fail: (err: any) => {
        console.error('File selection failed:', err)
        error.value = err
        onError?.(err)
      },
    }

    if (fileType === 'image') {
      // #ifdef MP-WEIXIN
      uni.chooseMedia({
        ...chooseFileOptions,
        mediaType: ['image'],
      })
      // #endif

      // #ifndef MP-WEIXIN
      uni.chooseImage(chooseFileOptions)
      // #endif
    }
    else {
      uni.chooseFile({
        ...chooseFileOptions,
        type: 'all',
      })
    }
  }

  return { loading, error, data, run }
}

async function uploadFile({
  tempFilePath,
  formData,
  onSuccess,
  onError,
  onComplete,
}: {
  tempFilePath: string
  formData: Record<string, any>
  onSuccess: (data: any) => void
  onError: (err: any) => void
  onComplete: () => void
}) {
  uni.uploadFile({
    url: VITE_UPLOAD_BASEURL,
    filePath: tempFilePath,
    name: 'file',
    formData,
    success: (uploadFileRes) => {
      try {
        const data = uploadFileRes.data
        onSuccess(data)
      }
      catch (err) {
        onError(err)
      }
    },
    fail: (err) => {
      console.error('Upload failed:', err)
      onError(err)
    },
    complete: onComplete,
  })
}
