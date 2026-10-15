Log in to AutoDL and rent an image
Select the image:
```
PyTorch / 2.1.0 / 3.10(ubuntu22.04) / cuda 12.1
```

After the machine boots, enable academic acceleration
```
source /etc/network_turbo
```

Go to the working directory
```
cd autodl-tmp/
```

Pull the project
```
git clone https://gitclone.com/github.com/fishaudio/fish-speech.git ; cd fish-speech
```

Install dependencies
```
pip install -e.
```

If you get an error, install portaudio
```
apt-get install portaudio19-dev -y
```

After installing, run
```
pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu121
```

Download the model
```
cd tools
python download_models.py 
```

After downloading the model, run the API
```
python -m tools.api_server --listen 0.0.0.0:6006 
```

Then go to the AutoDL instance page in a browser
```
https://autodl.com/console/instance/list
```

As shown below, click the `Custom Service` button of the machine you just created to enable the port forwarding service
![Custom Service](images/fishspeech/autodl-01.png)

After the port forwarding service is set up, open `http://localhost:6006/` on your local computer to access the fish-speech API
![Service Preview](images/fishspeech/autodl-02.png)


If you use the single-module deployment, the core configuration is as follows
```
selected_module:
  TTS: FishSpeech
TTS:
  FishSpeech:
    reference_audio: ["config/assets/wakeup_words.wav",]
    reference_text: ["Hello there, I'm Xiaozhi, a Taiwanese girl with a sweet voice. I'm super happy to meet you! What have you been up to lately? Don't forget to share something fun with me, I absolutely love gossip!",]
    api_key: "123"
    api_url: "http://127.0.0.1:6006/v1/tts"
```

Then restart the service