import { getEnvBaseUrl } from './index'
import { toast } from './toast'

/**
 * File upload hook usage example
 * @example
 * const { loading, error, data, progress, run } = useUpload<IUploadResult>(
 *   uploadUrl,
 *   {},
 *   {
 *     maxSize: 5, // max 5MB
 *     sourceType: ['album'], // album only
 *     onProgress: (p) => console.log(`upload progress: ${p}%`),
 *     onSuccess: (res) => console.log('Upload succeeded', res),
 *     onError: (err) => console.error('Upload failed', err),
 *   },
 * )
 */

/**
 * Upload URL configuration
 */
export const uploadFileUrl = {
  /** User avatar upload URL (reads the currently active BaseURL dynamically) */
  get USER_AVATAR() {
    return `${getEnvBaseUrl()}/user/avatar`
  },
}

/**
 * Generic file upload function (accepts a file path directly)
 * @param url upload URL
 * @param filePath local file path
 * @param formData extra form data
 * @param options upload options
 */
export function useFileUpload<T = string>(url: string, filePath: string, formData: Record<string, any> = {}, options: Omit<UploadOptions, 'sourceType' | 'sizeType' | 'count'> = {}) {
  return useUpload<T>(
    url,
    formData,
    {
      ...options,
      sourceType: ['album'],
      sizeType: ['original'],
    },
    filePath,
  )
}

export interface UploadOptions {
  /** Maximum number of images that can be selected, default 1 */
  count?: number
  /** Size of the selected images, original or compressed */
  sizeType?: Array<'original' | 'compressed'>
  /** Image source, album or camera */
  sourceType?: Array<'album' | 'camera'>
  /** File size limit in MB */
  maxSize?: number //
  /** Upload progress callback */
  onProgress?: (progress: number) => void
  /** Upload success callback */
  onSuccess?: (res: Record<string, any>) => void
  /** Upload failure callback */
  onError?: (err: Error | UniApp.GeneralCallbackResult) => void
  /** Upload completion callback (regardless of success or failure) */
  onComplete?: () => void
}

/**
 * File upload hook
 * @template T data type returned after a successful upload
 * @param url upload URL
 * @param formData extra form data
 * @param options upload options
 * @returns upload state and control object
 */
export function useUpload<T = string>(url: string, formData: Record<string, any> = {}, options: UploadOptions = {},
  /** Pass a file path directly, skipping the picker */
  directFilePath?: string) {
  /** Uploading state */
  const loading = ref(false)
  /** Upload error state */
  const error = ref(false)
  /** Response data after a successful upload */
  const data = ref<T>()
  /** Upload progress (0-100) */
  const progress = ref(0)

  /** Destructure upload options and set defaults */
  const {
    /** Maximum number of selectable images */
    count = 1,
    /** Size of the selected images */
    sizeType = ['original', 'compressed'],
    /** Image source */
    sourceType = ['album', 'camera'],
    /** File size limit (MB) */
    maxSize = 10,
    /** Progress callback */
    onProgress,
    /** Success callback */
    onSuccess,
    /** Failure callback */
    onError,
    /** Completion callback */
    onComplete,
  } = options

  /**
   * Check whether the file size exceeds the limit
   * @param size file size (bytes)
   * @returns whether the check passed
   */
  const checkFileSize = (size: number) => {
    const sizeInMB = size / 1024 / 1024
    if (sizeInMB > maxSize) {
      toast.warning(`File size cannot exceed ${maxSize}MB`)
      return false
    }
    return true
  }
  /**
   * Trigger file selection and upload
   * Use a different picker depending on the platform:
   * - WeChat mini program uses chooseMedia
   * - Other platforms use chooseImage
   */
  const run = () => {
    if (directFilePath) {
      // Use the provided file path directly
      loading.value = true
      progress.value = 0
      uploadFile<T>({
        url,
        tempFilePath: directFilePath,
        formData,
        data,
        error,
        loading,
        progress,
        onProgress,
        onSuccess,
        onError,
        onComplete,
      })
      return
    }

    // #ifdef MP-WEIXIN
    // Use the chooseMedia API in the WeChat mini program environment
    uni.chooseMedia({
      count,
      mediaType: ['image'], // images only
      sourceType,
      success: (res) => {
        const file = res.tempFiles[0]
        // Check whether the file size is within the limit
        if (!checkFileSize(file.size))
          return

        // Start upload
        loading.value = true
        progress.value = 0
        uploadFile<T>({
          url,
          tempFilePath: file.tempFilePath,
          formData,
          data,
          error,
          loading,
          progress,
          onProgress,
          onSuccess,
          onError,
          onComplete,
        })
      },
      fail: (err) => {
        console.error('Failed to choose media file:', err)
        error.value = true
        onError?.(err)
      },
    })
    // #endif

    // #ifndef MP-WEIXIN
    // Use the chooseImage API outside the WeChat mini program environment
    uni.chooseImage({
      count,
      sizeType,
      sourceType,
      success: (res) => {
        console.log('Image chosen:', res)

        // Start upload
        loading.value = true
        progress.value = 0
        uploadFile<T>({
          url,
          tempFilePath: res.tempFilePaths[0],
          formData,
          data,
          error,
          loading,
          progress,
          onProgress,
          onSuccess,
          onError,
          onComplete,
        })
      },
      fail: (err) => {
        console.error('Failed to choose image:', err)
        error.value = true
        onError?.(err)
      },
    })
    // #endif
  }

  return { loading, error, data, progress, run }
}

/**
 * File upload options interface
 * @template T data type returned after a successful upload
 */
interface UploadFileOptions<T> {
  /** upload URL */
  url: string
  /** Temporary file path */
  tempFilePath: string
  /** Extra form data */
  formData: Record<string, any>
  /** Response data after a successful upload */
  data: Ref<T | undefined>
  /** Upload error state */
  error: Ref<boolean>
  /** Uploading state */
  loading: Ref<boolean>
  /** Upload progress (0-100) */
  progress: Ref<number>
  /** Upload progress callback */
  onProgress?: (progress: number) => void
  /** Upload success callback */
  onSuccess?: (res: Record<string, any>) => void
  /** Upload failure callback */
  onError?: (err: Error | UniApp.GeneralCallbackResult) => void
  /** Upload completion callback */
  onComplete?: () => void
}

/**
 * Perform file upload
 * @template T data type returned after a successful upload
 * @param options upload options
 */
function uploadFile<T>({
  url,
  tempFilePath,
  formData,
  data,
  error,
  loading,
  progress,
  onProgress,
  onSuccess,
  onError,
  onComplete,
}: UploadFileOptions<T>) {
  try {
    // Create upload task
    const uploadTask = uni.uploadFile({
      url,
      filePath: tempFilePath,
      name: 'file', // key for the file
      formData,
      header: {
        // In H5 do not set Content-Type manually; let the browser handle the multipart format
        // #ifndef H5
        'Content-Type': 'multipart/form-data',
        // #endif
      },
      // Ensure the file name is valid
      success: (uploadFileRes) => {
        console.log('File uploaded:', uploadFileRes)
        try {
          // Parse response data
          const { data: _data } = JSON.parse(uploadFileRes.data)
          // Upload succeeded
          data.value = _data as T
          onSuccess?.(_data)
        }
        catch (err) {
          // Response parse error
          console.error('Failed to parse upload response:', err)
          error.value = true
          onError?.(new Error('Failed to parse upload response'))
        }
      },
      fail: (err) => {
        // Upload request failed
        console.error('File upload failed:', err)
        error.value = true
        onError?.(err)
      },
      complete: () => {
        // Runs regardless of success or failure
        loading.value = false
        onComplete?.()
      },
    })

    // Listen for upload progress
    uploadTask.onProgressUpdate((res) => {
      progress.value = res.progress
      onProgress?.(res.progress)
    })
  }
  catch (err) {
    // Failed to create upload task
    console.error('Failed to create upload task:', err)
    error.value = true
    loading.value = false
    onError?.(new Error('Failed to create upload task'))
  }
}
