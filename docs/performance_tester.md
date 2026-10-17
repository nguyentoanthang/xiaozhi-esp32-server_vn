# Usage Guide for the Performance Test Tool for Speech Recognition, Large Language Models, Non-Streaming Speech Synthesis, and Streaming Speech Synthesis

1. Create a data directory under main/xiaozhi-server
2. Create a .config.yaml file in the data directory
3. In .data/config.yaml, write the parameters for your speech recognition, large language model, and streaming speech synthesis
For example:
```
LLM:
  ChatGLMLLM:
    # Define the LLM API type
    type: openai
    # glm-4-flash is free, but you still need to register and fill in the api_key
    # You can find your api key here: https://bigmodel.cn/usercenter/proj-mgmt/apikeys
    model_name: glm-4-flash
    url: https://open.bigmodel.cn/api/paas/v4/
    api_key: your chat-glm web key

TTS:

ASR:
```
4. Run performance_tester.py in the main/xiaozhi-server directory: 
```
python performance_tester.py
```