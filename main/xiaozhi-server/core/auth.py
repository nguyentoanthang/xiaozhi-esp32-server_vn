import hmac
import base64
import hashlib
import time


class AuthenticationError(Exception):
    """Authentication exception"""

    pass


class AuthManager:
    """
    Unified authorization and authentication manager
    Generates and verifies the client_id / device_id / token (HMAC-SHA256) authentication triple
    The token contains no plaintext client_id/device_id, only a signature + timestamp; client_id/device_id are passed at connection time
    In MQTT, client_id: client_id, username: device_id, password: token
    In Websocket, header:{Device-ID: device_id, Client-ID: client_id, Authorization: Bearer token, ......}
    """

    def __init__(self, secret_key: str, expire_seconds: int = 60 * 60 * 24 * 30):
        if not expire_seconds or expire_seconds < 0:
            self.expire_seconds = 60 * 60 * 24 * 30
        else:
            self.expire_seconds = expire_seconds
        self.secret_key = secret_key

    def _sign(self, content: str) -> str:
        """Sign with HMAC-SHA256 and Base64-encode"""
        sig = hmac.new(
            self.secret_key.encode("utf-8"), content.encode("utf-8"), hashlib.sha256
        ).digest()
        return base64.urlsafe_b64encode(sig).decode("utf-8").rstrip("=")

    def generate_token(self, client_id: str, username: str) -> str:
        """
        Generate token
        Args:
            client_id: device connection ID
            username: device username (usually deviceId)
        Returns:
            str: token string
        """
        ts = int(time.time())
        content = f"{client_id}|{username}|{ts}"
        signature = self._sign(content)
        # The token contains only the signature and timestamp, no plaintext info
        token = f"{signature}.{ts}"
        return token

    def verify_token(self, token: str, client_id: str, username: str) -> bool:
        """
        Verify token validity
        Args:
            token: token passed in by the client
            client_id: client_id used by the connection
            username: username used by the connection
        """
        try:
            sig_part, ts_str = token.split(".")
            ts = int(ts_str)
            if int(time.time()) - ts > self.expire_seconds:
                return False  # Expired

            expected_sig = self._sign(f"{client_id}|{username}|{ts}")
            if not hmac.compare_digest(sig_part, expected_sig):
                return False

            return True
        except Exception:
            return False
