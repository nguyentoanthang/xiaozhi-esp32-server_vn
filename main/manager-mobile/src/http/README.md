# Request Library

The project currently uses Alova as the only HTTP request library:

## Usage

- **Alova HTTP**: path (src/http/request/alova.ts)
- **Example code**: src/api/foo-alova.ts and src/api/foo.ts
- **API docs**: https://alova.js.org/

## Configuration

The Alova instance is configured with:
- Automatic token authentication and refresh
- Unified error handling and prompts
- Dynamic domain switching
- Built-in request/response interceptors

## Examples

```typescript
import { http } from '@/http/request/alova'

// GET request
http.Get<ResponseType>('/api/path', {
  params: { id: 1 },
  headers: { 'Custom-Header': 'value' },
  meta: { toast: false } // Disable error toast
})

// POST request
http.Post<ResponseType>('/api/path', data, {
  params: { query: 'param' },
  headers: { 'Content-Type': 'application/json' }
})
```