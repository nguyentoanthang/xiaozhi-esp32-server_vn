// Generic response format
export interface IResponse<T = any> {
  code: number | string
  data: T
  msg: string
  status: string | number
}

// Pagination request parameters
export interface PageParams {
  page: number
  pageSize: number
  [key: string]: any
}

// Pagination response data
export interface PageResult<T> {
  list: T[]
  total: number
  page: number
  pageSize: number
}
