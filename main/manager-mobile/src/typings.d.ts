// Put globally used types here

declare global {
  interface IResData<T> {
    code: number
    msg: string
    data: T
  }

  // uni.uploadFile upload parameters
  interface IUniUploadFileOptions {
    file?: File
    files?: UniApp.UploadFileOptionFiles[]
    filePath?: string
    name?: string
    formData?: any
  }

  interface IUserInfo {
    nickname?: string
    avatar?: string
    /** WeChat openid, this field does not exist outside WeChat */
    openid?: string
    token?: string
  }
}

export {} // Prevent module pollution
