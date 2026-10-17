import asyncio
import time
import json
import uuid
import aiohttp
import websockets
import hmac
import base64
import hashlib
import asyncio
from urllib.parse import urlparse, urlencode
from tabulate import tabulate
from config.settings import load_config

description = "Streaming TTS first-word time test"
class StreamTTSPerformanceTester:
    def __init__(self, config):
        self.config = config
        self.test_texts = [
            "Hello, this is a sentence."
        ]
        self.results = []
    
    async def test_paddlespeech_tts(self, text=None, test_count=5):
        """Test PaddleSpeech streaming TTS first-word latency (average over multiple runs)"""
        text = text or self.test_texts[0]
        latencies = []
        
        for i in range(test_count):
            try:
                tts_config = self.config["TTS"]["PaddleSpeechTTS"]
                tts_url = tts_config["url"]
                spk_id = tts_config["spk_id"]
                speed = tts_config["speed"]
                volume = tts_config["volume"]

                start_time = time.time()
                async with websockets.connect(tts_url) as ws:
                    # Send the start request
                    await ws.send(json.dumps({
                        "task": "tts",
                        "signal": "start"
                    }))
                    
                    start_response = json.loads(await ws.recv())
                    if start_response.get("status") != 0:
                        raise Exception("Connection failed")
                    
                    # Send text data
                    await ws.send(json.dumps({
                        "text": text,
                        "spk_id": spk_id,
                        "speed": speed,
                        "volume": volume
                    }))
                    
                    # Receive the first data chunk
                    first_chunk = await ws.recv()
                    latency = time.time() - start_time
                    latencies.append(latency)
                    print(f"[PaddleSpeechTTS] run {i+1} first-word latency: {latency:.3f}s")

                    # Send the end request
                    end_request = {
                        "task": "tts",
                        "signal": "end"
                    }
                    await ws.send(json.dumps(end_request))

                    # Make sure the connection closes cleanly
                    try:
                        await ws.recv()
                    except websockets.exceptions.ConnectionClosedOK:
                        pass

            except Exception as e:
                print(f"[PaddleSpeechTTS] run {i+1} test failed: {str(e)}")
                latencies.append(None)
        
        return self._calculate_result("PaddleSpeechTTS", latencies, test_count)
            
    async def test_linkerai_tts(self, text=None, test_count=5):
        """Test Linkerai streaming TTS first-word latency (average over multiple runs)"""
        text = text or self.test_texts[0]
        latencies = []
        
        for i in range(test_count):
            try:
                tts_config = self.config["TTS"]["LinkeraiTTS"]
                api_url = tts_config["api_url"]
                access_token = tts_config["access_token"]
                voice = tts_config["voice"]

                # Unified timing start: start timing before establishing the connection
                start_time = time.time()
                async with aiohttp.ClientSession() as session:
                    params = {
                        "tts_text": text,
                        "spk_id": voice,
                        "frame_durition": 60,
                        "stream": "true",
                        "target_sr": 16000,
                        "audio_format": "pcm",
                        "instruct_text": "Please generate natural and fluent speech",
                    }
                    headers = {
                        "Authorization": f"Bearer {access_token}",
                        "Content-Type": "application/json",
                    }

                    async with session.get(api_url, params=params, headers=headers, timeout=10) as resp:
                        if resp.status != 200:
                            raise Exception(f"Request failed: {resp.status}, {await resp.text()}")

                        # Receive the first data chunk
                        async for _ in resp.content.iter_any():
                            latency = time.time() - start_time
                            latencies.append(latency)
                            print(f"[LinkeraiTTS] run {i+1} first-word latency: {latency:.3f}s")
                            break
                        else:
                            latencies.append(None)

            except Exception as e:
                print(f"[LinkeraiTTS] run {i+1} test failed: {str(e)}")
                latencies.append(None)
        
        return self._calculate_result("LinkeraiTTS", latencies, test_count)
    
    def _create_xunfei_auth_url(self, api_key, api_secret, api_url):
        """Generate the Xunfei WebSocket authentication URL"""
        parsed_url = urlparse(api_url)
        host = parsed_url.netloc
        path = parsed_url.path
        
        # Get UTC time; Xunfei requires RFC1123 format
        now = time.gmtime()
        date = time.strftime('%a, %d %b %Y %H:%M:%S GMT', now)
        
        # Build the signature string
        signature_origin = f"host: {host}\ndate: {date}\nGET {path} HTTP/1.1"
        
        # Compute the signature
        signature_sha = hmac.new(
            api_secret.encode('utf-8'),
            signature_origin.encode('utf-8'),
            digestmod=hashlib.sha256
        ).digest()
        signature_sha_base64 = base64.b64encode(signature_sha).decode(encoding='utf-8')
        
        # Build the authorization
        authorization_origin = f'api_key="{api_key}", algorithm="hmac-sha256", headers="host date request-line", signature="{signature_sha_base64}"'
        authorization = base64.b64encode(authorization_origin.encode('utf-8')).decode(encoding='utf-8')
        
        # Build the final WebSocket URL
        v = {
            "authorization": authorization,
            "date": date,
            "host": host
        }
        url = api_url + '?' + urlencode(v)
        return url
    
    def _build_xunfei_request(self, app_id, text, voice):
        """Build the Xunfei TTS request structure"""
        return {
            "header": {
                "app_id": app_id,
                "status": 2,
            },
            "parameter": {
                "oral": {
                    "oral_level": "mid",
                    "spark_assist": 1,
                    "stop_split": 0,
                    "remain": 0
                },
                "tts": {
                    "vcn": voice,
                    "speed": 50,
                    "volume": 50,
                    "pitch": 50,
                    "bgs": 0,
                    "reg": 0,
                    "rdn": 0,
                    "rhy": 0,
                    "audio": {
                        "encoding": "raw",
                        "sample_rate": 24000,
                        "channels": 1,
                        "bit_depth": 16,
                        "frame_size": 0
                    }
                }
            },
            "payload": {
                "text": {
                    "encoding": "utf8",
                    "compress": "raw",
                    "format": "plain",
                    "status": 2,
                    "seq": 1,
                    "text": base64.b64encode(text.encode('utf-8')).decode('utf-8')
                }
            }
        }


    def _calculate_result(self, service_name, latencies, test_count):
        """Calculate test results (handle None values correctly and exclude failed tests)"""
        # Exclude failed tests (None values and latencies <= 0); count only valid latencies
        valid_latencies = [l for l in latencies if l is not None and l > 0]
        if valid_latencies:
            avg_latency = sum(valid_latencies) / len(valid_latencies)
            status = f"Success ({len(valid_latencies)}/{test_count} valid runs)"
        else:
            avg_latency = 0
            status = "Failed: all tests failed"
        return {"name": service_name, "latency": avg_latency, "status": status}

    def _print_results(self, test_text, test_count):
        """Print test results"""
        if not self.results:
            print("No valid TTS test results")
            return

        print(f"\n{'='*60}")
        print("Streaming TTS first-word latency test results")
        print(f"{'='*60}")
        print(f"Test text: {test_text}")
        print(f"Test runs: {test_count} per TTS service")

        # Sort results: successful first, by ascending latency
        success_results = sorted(
            [r for r in self.results if "Success" in r["status"]],
            key=lambda x: x["latency"]
        )
        failed_results = [r for r in self.results if "Success" not in r["status"]]

        table_data = [
            [r["name"], f"{r['latency']:.3f}", r["status"]]
            for r in success_results + failed_results
        ]

        print(tabulate(table_data, headers=["TTS service", "First-word latency (s)", "Status"], tablefmt="grid"))
        print("\nTest notes: measures the time from establishing the connection to receiving the first audio data chunk (including handshake, authentication, and sending text), averaged over multiple runs")
        print("- Timing start: before the WebSocket/HTTP connection is established (uniformly covers connection setup, handshake, and sending text)")
        print("- Timeout control: maximum wait time per request is 10 seconds")
        print("- Error handling: failed tests are excluded from the average; only successful tests count toward latency")
        print("- Sort order: by average time, fastest to slowest")


    async def run(self, test_text=None, test_count=5):
        """Run the test
        
        Args:
            test_text: text to test; the default text is used if None
            test_count: number of test runs per TTS service
        """
        test_text = test_text or self.test_texts[0]
        print(f"Starting streaming TTS first-word latency test...")
        print(f"Test text: {test_text}")
        print(f"Test runs per TTS service: {test_count}")
        
        if not self.config.get("TTS"):
            print("No TTS configuration found in the config file")
            return
        
        # Test each TTS service
        self.results = []
        
        # Test PaddleSpeech TTS
        result = await self.test_paddlespeech_tts(test_text, test_count)
        self.results.append(result)
        
        # Test Linkerai TTS
        result = await self.test_linkerai_tts(test_text, test_count)
        self.results.append(result)
        
        # Print results
        self._print_results(test_text, test_count)


async def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Streaming TTS first-word latency test tool")
    parser.add_argument("--text", help="Text content to test")
    parser.add_argument("--count", type=int, default=5, help="number of test runs per TTS service")
    
    args = parser.parse_args()
    config = await load_config()
    await StreamTTSPerformanceTester(config).run(args.text, args.count)


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
