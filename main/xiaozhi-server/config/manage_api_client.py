import os
import base64
import functools
import threading
from typing import Optional, Dict

import httpx

TAG = __name__


class DeviceNotFoundException(Exception):
    pass


class DeviceBindException(Exception):
    def __init__(self, bind_code):
        self.bind_code = bind_code
        super().__init__(f"Device binding error, bind code: {bind_code}")


class ManageApiClient:
    _instance = None
    _instance_lock = threading.Lock()  # Protects reads and writes of _instance and _closed
    _async_clients = {}  # Stores an independent client for each event loop
    _secret = None
    _closed = False  # Set to True after safe_close(); no new connections are created once closed

    def __new__(cls, config):
        """Singleton pattern ensures a globally unique instance and supports passing config parameters"""
        with cls._instance_lock:
            if cls._instance is None:
                cls._instance = super().__new__(cls)
                cls._init_client(config)
            return cls._instance

    @classmethod
    def _init_client(cls, config):
        """Initialize the config (the client is created lazily)"""
        cls.config = config.get("manager-api")

        if not cls.config:
            raise Exception("manager-api config error")

        if not cls.config.get("url") or not cls.config.get("secret"):
            raise Exception("manager-api url or secret config error")

        if "your_" in cls.config.get("secret"):
            raise Exception("Please configure the manager-api secret first")

        cls._secret = cls.config.get("secret")
        cls.max_retries = cls.config.get("max_retries", 6)  # Maximum number of retries
        cls.retry_delay = cls.config.get("retry_delay", 10)  # Initial retry delay (seconds)
        # Do not create the AsyncClient here; create it lazily on actual use
        cls._async_clients = {}
        cls._closed = False

    @classmethod
    async def _ensure_async_client(cls):
        """Ensure the async client has been created (an independent client is created for each event loop)"""
        import asyncio

        try:
            loop = asyncio.get_running_loop()
            loop_id = id(loop)

            # Checking the closed state and creating the connection pool must be in the same critical section, to avoid a request writing a new client back after safe_close()
            # has cleared the connection pool.
            with cls._instance_lock:
                if cls._closed:
                    raise Exception("ManageApiClient is closed; no new HTTP client will be created")

                if loop_id not in cls._async_clients:
                    # The server may close connections proactively, and the httpx connection pool cannot detect and clean them up correctly
                    limits = httpx.Limits(
                        max_keepalive_connections=0,  # Disable keep-alive; create a new connection every time
                    )
                    cls._async_clients[loop_id] = httpx.AsyncClient(
                        base_url=cls.config.get("url"),
                        headers={
                            "User-Agent": f"PythonClient/2.0 (PID:{os.getpid()})",
                            "Accept": "application/json",
                            "Authorization": "Bearer " + cls._secret,
                        },
                        timeout=cls.config.get("timeout", 30),
                        limits=limits,  # Apply the limits
                        trust_env=False,
                    )
                return cls._async_clients[loop_id]
        except RuntimeError:
            # If there is no running event loop, create a temporary one
            raise Exception("Must be called in an async context")

    @classmethod
    async def _async_request(cls, method: str, endpoint: str, **kwargs) -> Dict:
        """Send a single async HTTP request and handle the response"""
        # Ensure the client has been created
        client = await cls._ensure_async_client()
        endpoint = endpoint.lstrip("/")
        response = None
        try:
            response = await client.request(method, endpoint, **kwargs)
            response.raise_for_status()

            result = response.json()

            # Handle business errors returned by the API
            if result.get("code") == 10041:
                raise DeviceNotFoundException(result.get("msg"))
            elif result.get("code") == 10042:
                raise DeviceBindException(result.get("msg"))
            elif result.get("code") != 0:
                raise Exception(f"API returned an error: {result.get('msg', 'unknown error')}")

            # Return the successful data
            return result.get("data") if result.get("code") == 0 else None
        finally:
            # Ensure the response is closed (runs even on exceptions)
            if response is not None:
                await response.aclose()

    @classmethod
    def _should_retry(cls, exception: Exception) -> bool:
        """Decide whether the exception should be retried"""
        # Network connection related errors
        if isinstance(
            exception, (httpx.ConnectError, httpx.TimeoutException, httpx.NetworkError)
        ):
            return True

        # HTTP status code errors
        if isinstance(exception, httpx.HTTPStatusError):
            status_code = exception.response.status_code
            return status_code in [408, 429, 500, 502, 503, 504]

        return False

    @classmethod
    async def _execute_async_request(cls, method: str, endpoint: str, **kwargs) -> Dict:
        """Async request executor with a retry mechanism"""
        import asyncio

        retry_count = 0

        while retry_count <= cls.max_retries:
            try:
                # Execute the async request
                return await cls._async_request(method, endpoint, **kwargs)
            except Exception as e:
                # Decide whether to retry
                if retry_count < cls.max_retries and cls._should_retry(e):
                    retry_count += 1
                    print(
                        f"{method} {endpoint} async request failed, retry #{retry_count} in {cls.retry_delay:.1f} seconds"
                    )
                    await asyncio.sleep(cls.retry_delay)
                    continue
                else:
                    # Do not retry; raise the exception directly
                    raise

    @classmethod
    def _get_instance(cls):
        """Get the singleton instance reference in a thread-safe way

        Callers should use the returned local reference instead of reading
        ManageApiClient._instance again after a null check: even if safe_close() later sets _instance
        to None, the reference already obtained still points to the original object, which eliminates the TOCTOU race window of "the instance being
        set to None after the null check but before use".
        """
        with cls._instance_lock:
            return cls._instance

    @classmethod
    def safe_close(cls):
        """Safely close all async connection pools"""
        import asyncio

        with cls._instance_lock:
            cls._closed = True
            clients = list(cls._async_clients.values())
            cls._async_clients.clear()
            cls._instance = None

        for client in clients:
            try:
                asyncio.run(client.aclose())
            except Exception:
                pass


def api_guard(error_msg: str = None, raise_when_closed: bool = False):
    """Decorator: uniformly obtains the singleton instance, handles null checks and exception fallback

    - Obtains a local instance reference once via _get_instance() and injects it as the
      first argument of the decorated function, eliminating the TOCTOU race window with safe_close();
    - When the instance is uninitialized or closed: raise_when_closed=True raises an explicit exception
      (for startup-path functions), otherwise silently returns None (for daemon-thread paths);
    - When error_msg is not None, request exceptions are caught, logged, and None is returned;
      when it is None, the exception is re-raised as-is for the caller to handle.
    """

    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            instance = ManageApiClient._get_instance()
            if instance is None:
                if raise_when_closed:
                    raise Exception("ManageApiClient is uninitialized or closed")
                return None
            if error_msg is None:
                return await func(instance, *args, **kwargs)
            try:
                return await func(instance, *args, **kwargs)
            except Exception as e:
                print(f"{error_msg}: {e}")
                return None

        return wrapper

    return decorator


@api_guard(raise_when_closed=True)
async def get_server_config(instance) -> Optional[Dict]:
    """Get the server base config"""
    return await instance._execute_async_request("POST", "/config/server-base")


@api_guard(raise_when_closed=True)
async def get_agent_models(
    instance, mac_address: str, client_id: str, selected_module: Dict
) -> Optional[Dict]:
    """Get the agent model config"""
    return await instance._execute_async_request(
        "POST",
        "/config/agent-models",
        json={
            "macAddress": mac_address,
            "clientId": client_id,
            "selectedModule": selected_module,
        },
    )


@api_guard("Failed to get replacement words")
async def get_correct_words(instance, mac_address: str) -> Optional[Dict]:
    """Get the agent replacement words"""
    return await instance._execute_async_request(
        "POST", "/config/correct-words",
        json={"macAddress": mac_address}
    )


@api_guard("Failed to generate and save chat history summary")
async def generate_and_save_chat_summary(instance, session_id: str) -> Optional[Dict]:
    """Generate and save the chat history summary (called in a daemon thread; silently returns None if the service is closed)"""
    return await instance._execute_async_request(
        "POST",
        f"/agent/chat-summary/{session_id}/save",
    )


@api_guard("Failed to generate and save chat title")
async def generate_and_save_chat_title(instance, session_id: str) -> Optional[Dict]:
    """Generate and save the chat title (called in a daemon thread; silently returns None if the service is closed)"""
    return await instance._execute_async_request(
        "POST",
        f"/agent/chat-title/{session_id}/generate",
    )


@api_guard("TTS report failed")
async def report(
    instance, mac_address: str, session_id: str, chat_type: int, content: str, audio, report_time
) -> Optional[Dict]:
    """Report chat history asynchronously"""
    if not content:
        return None
    return await instance._execute_async_request(
        "POST",
        f"/agent/chat-history/report",
        json={
            "macAddress": mac_address,
            "sessionId": session_id,
            "chatType": chat_type,
            "content": content,
            "reportTime": report_time,
            "audioBase64": (
                base64.b64encode(audio).decode("utf-8") if audio else None
            ),
        },
    )


@api_guard("Contact lookup failed")
async def lookup_address_book(instance, caller_mac: str, nickname: str) -> Optional[Dict]:
    """Find the target device by nickname"""
    return await instance._execute_async_request(
        "GET",
        f"/device/address-book/lookup?callerMac={caller_mac}&nickname={nickname}",
    )


def init_service(config):
    ManageApiClient(config)


def manage_api_http_safe_close():
    ManageApiClient.safe_close()
