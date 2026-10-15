# Context Provider Usage Guide

## Overview

A `context provider` adds a [data source] to the context of Xiaozhi's system prompt.

At the moment Xiaozhi wakes up, a `context provider` fetches data from external systems and dynamically injects it into the LLM's system prompt.
This lets it perceive the state of something in the world when it wakes up.

It is fundamentally different from MCP and memory: a `context provider` forces Xiaozhi to be aware of real-world data; `Memory (Mem)` lets it know what was discussed before; `MCP (function_call)` is invoked when a certain capability or piece of knowledge is needed.

With this feature, at the instant Xiaozhi wakes up, it can "perceive":
- Health sensor status (body temperature, blood pressure, blood oxygen, etc.)
- Real-time data from business systems (server load, to-do items, stock information, etc.)
- Any text information available through an HTTP API

**Note**: This feature only lets Xiaozhi perceive the state of things at wake-up. If you want Xiaozhi to obtain the state of things in real time after waking up, it is recommended to combine this feature with MCP tool calls.

## How It Works

1. **Configure sources**: The user configures one or more HTTP API addresses.
2. **Trigger requests**: When the system builds the prompt, if the template contains the `{{ dynamic_context }}` placeholder, it requests all configured APIs.
3. **Automatic injection**: The system automatically formats the data returned by the APIs as a Markdown list and replaces the `{{ dynamic_context }}` placeholder.

## API Specification

For Xiaozhi to parse the data correctly, your API must meet the following specification:

- **Request method**: `GET`
- **Request headers**: The system automatically adds a `device-id` field to the request header.
- **Response format**: Must return JSON containing the `code` and `data` fields.

### Response Examples

**Case 1: Return key-value pairs**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "Living room temperature": "26℃",
    "Living room humidity": "45%",
    "Front door status": "Closed"
  }
}
```
*Injection result:*
```markdown
<context>
- **Living room temperature:** 26℃
- **Living room humidity:** 45%
- **Front door status:** Closed
</context>
```

**Case 2: Return a list**
```json
{
  "code": 0,
  "data": [
    "You have 10 to-do items",
    "The car's current speed is 100 km/h"
  ]
}
```
*Injection result:*
```markdown
<context>
- You have 10 to-do items
- The car's current speed is 100 km/h
</context>
```

## Configuration Guide

### Method 1: Control Panel configuration (full-module deployment)

1. Log in to the Control Panel and go to the **Role Configuration** page.
2. Find the **Context Provider** setting (click the "Edit Sources" button).
3. Click **Add** and enter your API address.
4. If the API requires authentication, add `Authorization` or other headers in the **Request Headers** section.
5. Save the configuration.

### Method 2: Configuration file (single-module deployment)

Edit the `xiaozhi-server/data/.config.yaml` file and add the `context_providers` section:

```yaml
# Context provider configuration
context_providers:
  - url: "http://api.example.com/data"
    headers:
      Authorization: "Bearer your-token"
  - url: "http://another-api.com/data"
```

## Enabling the Feature

By default, the `{{ dynamic_context }}` placeholder is already built into the system's prompt template file (`data/.agent-base-prompt.txt`), so you do not need to add it manually.

**Example:**

```markdown
<context>
[Important! The following information has been provided in real time. There is no need to call a tool to query it; use it directly:]
- **Device ID:** {{device_id}}
- **Current time:** {{current_time}}
...
{{ dynamic_context }}
</context>
```

**Note**: If you do not need this feature, you can choose to **configure no context providers**, or **delete** the `{{ dynamic_context }}` placeholder from the prompt template file.

## Appendix: Mock Test Server Example

To make testing and development easier, we provide a simple Python Mock Server script. You can run this script to simulate API endpoints locally.

**mock_api_server.py**

```python
import http.server
import socketserver
import json
from urllib.parse import urlparse, parse_qs

# Set the port number
PORT = 8081

class MockRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse the path and parameters
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query = parse_qs(parsed_path.query)

        response_data = {}
        status_code = 200

        print(f"Request received: {path}, params:  {query}")

        # Case 1: Simulate health data (returns a dict)
        # Path style: /health
        # device_id is taken from the header
        if path == "/health":
            device_id = self.headers.get("device-id", "unknown_device")
            print(f"device_id: {device_id}")
            response_data = {
                "code": 0,
                "msg": "success",
                "data": {
                    "Test device ID": device_id,
                    "Heart rate": "80 bpm",
                    "Blood pressure": "120/80 mmHg",
                    "Status": "Good"
                }
            }

        # Case 2: Simulate a news list (returns a list)
        # No parameters: /news/list
        elif path == "/news/list":
            response_data = {
                "code": 0,
                "msg": "success",
                "data": [
                    "Headline: Python 3.14 released",
                    "Tech news: AI assistants change lives",
                    "Local news: Heavy rain tomorrow, remember to bring an umbrella"
                ]
            }

        # Case 3: Simulate a weather brief (returns a string)
        # No parameters: /weather/simple
        elif path == "/weather/simple":
            response_data = {
                "code": 0,
                "msg": "success",
                "data": "Sunny turning cloudy today, 20-25 degrees, excellent air quality, good for going out."
            }

        # Case 4: Simulate device details (query parameter style)
        # Parameter style: /device/info
        # device_id is taken from the header
        elif path == "/device/info":
            device_id = self.headers.get("device-id", "unknown_device")
            response_data = {
                "code": 0,
                "msg": "success",
                "data": {
                    "Query method": "Header parameter",
                    "Device ID": device_id,
                    "Battery": "85%",
                    "Firmware": "v2.0.1"
                }
            }
        
        # Case 5: 404 Not Found
        else:
            status_code = 404
            response_data = {"error": "Endpoint does not exist"}

        # Send the response
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json; charset=utf-8')
        self.end_headers()
        self.wfile.write(json.dumps(response_data, ensure_ascii=False).encode('utf-8'))

# Start the server
# Allow address reuse to avoid errors on quick restarts
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), MockRequestHandler) as httpd:
    print(f"==================================================")
    print(f"Mock API Server started: http://localhost:{PORT}")
    print(f"Available endpoints:")
    print(f"1. [dict] http://localhost:{PORT}/health")
    print(f"2. [list] http://localhost:{PORT}/news/list")
    print(f"3. [text] http://localhost:{PORT}/weather/simple")
    print(f"4. [params] http://localhost:{PORT}/device/info")
    print(f"==================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
```
