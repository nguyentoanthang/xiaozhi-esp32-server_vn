# IndexStreamTTS Usage Guide

## Environment Preparation
### 1. Clone the project 
```bash 
git clone https://github.com/Ksuriuri/index-tts-vllm.git
```
Go to the extracted directory
```bash
cd index-tts-vllm
```
Switch to the specified version (a historical version that uses VLLM-0.10.2)
```bash
git checkout 224e8d5e5c8f66801845c66b30fa765328fd0be3
```

### 2. Create and activate a conda environment
```bash 
conda create -n index-tts-vllm python=3.12
conda activate index-tts-vllm
```

### 3. Install PyTorch (version 2.8.0 required, the latest version)
#### Check the highest CUDA version supported by the GPU and the version actually installed
```bash
nvidia-smi
nvcc --version
``` 
#### Highest CUDA version supported by the driver
```bash
CUDA Version: 12.8
```
#### CUDA compiler version actually installed
```bash
Cuda compilation tools, release 12.8, V12.8.89
```
#### The corresponding install command (pytorch defaults to the CUDA 12.8 build)
```bash
pip install torch torchvision
```
pytorch version 2.8.0 is required (corresponding to vllm 0.10.2). For the exact install command, see the [pytorch website](https://pytorch.org/get-started/locally/)

### 4. Install dependencies
```bash 
pip install -r requirements.txt
```

### 5. Download the model weights
### Option 1: Download the official weights and convert them
These are the official weight files. Download them to any local path; the IndexTTS-1.5 weights are supported.  
| HuggingFace                                                   | ModelScope                                                          |
|---------------------------------------------------------------|---------------------------------------------------------------------|
| [IndexTTS](https://huggingface.co/IndexTeam/Index-TTS)        | [IndexTTS](https://modelscope.cn/models/IndexTeam/Index-TTS)        |
| [IndexTTS-1.5](https://huggingface.co/IndexTeam/IndexTTS-1.5) | [IndexTTS-1.5](https://modelscope.cn/models/IndexTeam/IndexTTS-1.5) |

The following uses the ModelScope installation method as an example.  
#### Note: git must be installed and initialized with lfs enabled (skip if already installed)
```bash
sudo apt-get install git-lfs
git lfs install
```
Create the model directory and pull the model
```bash 
mkdir model_dir
cd model_dir
git clone https://www.modelscope.cn/IndexTeam/IndexTTS-1.5.git
```

#### Model weight conversion
```bash 
bash convert_hf_format.sh /path/to/your/model_dir
```
For example, if the IndexTTS-1.5 model you downloaded is stored in the model_dir directory, run the following command
```bash
bash convert_hf_format.sh model_dir/IndexTTS-1.5
```
This converts the official model weights into a version compatible with the transformers library and saves them in the vllm folder under the model weights path, so that the vllm library can load the model weights later

### 6. Modify the API to fit the project
The data returned by the API does not fit the project and needs to be adjusted so that it returns the audio data directly
```bash
vi api_server.py
```
```bash 
@app.post("/tts", responses={
    200: {"content": {"application/octet-stream": {}}},
    500: {"content": {"application/json": {}}}
})
async def tts_api(request: Request):
    try:
        data = await request.json()
        text = data["text"]
        character = data["character"]

        global tts
        sr, wav = await tts.infer_with_ref_audio_embed(character, text)

        return Response(content=wav.tobytes(), media_type="application/octet-stream")
        
    except Exception as ex:
        tb_str = ''.join(traceback.format_exception(type(ex), ex, ex.__traceback__))
        print(tb_str)
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "error": str(tb_str)
            }
        )
```

### 7. Write the sh startup script (note: it must be run in the corresponding conda environment)
```bash 
vi start_api.sh
```
### Paste in the following content, then press : and type wq to save  
#### Change /home/system/index-tts-vllm/model_dir/IndexTTS-1.5 in the script to the actual path
```bash
# Activate the conda environment
conda activate index-tts-vllm 
echo "Activating the project conda environment"
sleep 2
# Find the process ID using port 11996
PID_VLLM=$(sudo netstat -tulnp | grep 11996 | awk '{print $7}' | cut -d'/' -f1)

# Check whether a process ID was found
if [ -z "$PID_VLLM" ]; then
  echo "No process found using port 11996"
else
  echo "Found a process using port 11996, process ID: $PID_VLLM"
  # Try a normal kill first, then wait 2 seconds
  kill $PID_VLLM
  sleep 2
  # Check whether the process is still alive
  if ps -p $PID_VLLM > /dev/null; then
    echo "Process is still running, force killing..."
    kill -9 $PID_VLLM
  fi
  echo "Terminated process $PID_VLLM"
fi

# Find the VLLM::EngineCore processes
GPU_PIDS=$(ps aux | grep -E "VLLM|EngineCore" | grep -v grep | awk '{print $2}')

# Check whether a process ID was found
if [ -z "$GPU_PIDS" ]; then
  echo "No VLLM-related processes found"
else
  echo "Found VLLM-related processes, process IDs: $GPU_PIDS"
  # Try a normal kill first, then wait 2 seconds
  kill $GPU_PIDS
  sleep 2
  # Check whether the process is still alive
  if ps -p $GPU_PIDS > /dev/null; then
    echo "Process is still running, force killing..."
    kill -9 $GPU_PIDS
  fi
  echo "Terminated processes $GPU_PIDS"
fi

# Create the tmp directory (if it does not exist)
mkdir -p tmp

# Run api_server.py in the background, redirecting the log to tmp/server.log
nohup python api_server.py --model_dir /home/system/index-tts-vllm/model_dir/IndexTTS-1.5 --port 11996 > tmp/server.log 2>&1 &
echo "api_server.py is running in the background; see tmp/server.log for the log"
```
Give the script execute permission and run it
```bash 
chmod +x start_api.sh
./start_api.sh
```
The log is written to tmp/server.log. You can view it with the following command
```bash
tail -f tmp/server.log
```
If the GPU has enough memory, you can add the startup parameter ----gpu_memory_utilization to the script to adjust the proportion of GPU memory used. The default value is 0.25

## Voice Configuration
index-tts-vllm supports registering custom voices through a configuration file, with both single-voice and mixed-voice configurations.  
Configure custom voices in the assets/speaker.json file under the project root directory
### Configuration Format
```bash
{
    "speaker-name-1": [
        "audio-file-path-1.wav",
        "audio-file-path-2.wav"
    ],
    "speaker-name-2": [
        "audio-file-path-3.wav"
    ]
}
```
### Note (restart the service after configuring a speaker to register the voice)
After adding it, add the corresponding speaker in the Control Panel (for the single-module deployment, change the corresponding voice)