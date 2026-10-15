This is a development document. To deploy the Xiaozhi server, [click here for the deployment guide](../../README.md#deployment-documentation)

For all-in-one digital human deployment, Kiosk fullscreen launch, and system environment configuration, [click here for the all-in-one deployment guide](../../docs/all-in-one-digital-human-setup.md)

For wake word model download, runtime configuration, and detailed usage, [click here for the wake word documentation](../../docs/digital-human-wakeword.md)

# Introduction

digital-human is a standalone digital human test module. It provides a local test page, frontend interaction resources, a wake word runtime, and an event bridge, and is used to debug the whole digital human interaction pipeline end to end.

# Quick Start

Install dependencies:

```bash
pip install -r wakeword_runtime/requirements.txt
```

Start the module:

```bash
python start.py
```

# Access URLs

After startup you can access:

- Page URL:http://127.0.0.1:8006/index.html
- Event bridge URL:ws://127.0.0.1:8006/wakeword-ws
- Health check:http://127.0.0.1:8006/health

# Directory Layout

- `start.py`: module entry point
- `index.html`: digital human test page entry
- `wakeword_runtime`: local wake word runtime and configuration directory
- `js`, `css`: page frontend scripts and styles
- `images`, `resources`: page resource files

# Related Documents

- All-in-one deployment guide: for deploying on complete x86 devices, Kiosk display, and boot auto-start configuration
	[../../docs/all-in-one-digital-human-setup.md](../../docs/all-in-one-digital-human-setup.md)
- Wake word documentation: for wake word model download, runtime configuration, and local debugging
	[../../docs/digital-human-wakeword.md](../../docs/digital-human-wakeword.md)
