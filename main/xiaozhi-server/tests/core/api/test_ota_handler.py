"""OTA endpoint of the minimal server: WebSocket URL only (no MQTT block), firmware links, no vision route."""
import importlib
import sys
import types

import pytest
from aiohttp import web
from aiohttp.test_utils import TestClient, TestServer
from loguru import logger

HEADERS = {"device-id": "aa:bb:cc:dd:ee:ff", "client-id": "c1"}
BODY = {"board": {"type": "boardx"}, "application": {"version": "1.0.0"}}
MODULES = ("core.utils.util", "core.api.base_handler", "core.api.ota_handler", "core.http_server")


@pytest.fixture
def ota(monkeypatch):
    """Import the OTA modules with a plain logger. A pydub stub is used only if pydub is not installed
    (core.utils.util imports it; the OTA code never uses it), and nothing leaks into other tests."""
    before = set(sys.modules)
    try:
        import pydub  # noqa: F401
    except ImportError:
        stub = types.ModuleType("pydub")
        stub.AudioSegment = object
        monkeypatch.setitem(sys.modules, "pydub", stub)
    # Handlers call setup_logging() in their constructor, which would open the real database
    import config.logger as config_logger

    monkeypatch.setattr(config_logger, "setup_logging", lambda *a, **k: logger)
    for name in MODULES:  # re-import, so that they bind the patched setup_logging
        monkeypatch.delitem(sys.modules, name, raising=False)
    loaded = {name: importlib.import_module(name) for name in MODULES}
    yield types.SimpleNamespace(
        OTAHandler=loaded["core.api.ota_handler"].OTAHandler,
        SimpleHttpServer=loaded["core.http_server"].SimpleHttpServer,
        util=loaded["core.utils.util"],
    )
    for name in set(sys.modules) - before:
        if name.startswith("core.") or name == "pydub":
            sys.modules.pop(name, None)


def _config(**server):
    base = {
        "auth_key": "k",
        "port": 8000,
        "http_port": 8003,
        "websocket": "ws://example.lan:8000/xiaozhi/v1/",
        "timezone_offset": 7,
    }
    base.update(server)
    return {"server": base}


async def _post(handler):
    app = web.Application()
    app.add_routes([web.post("/xiaozhi/ota/", handler.handle_post)])
    async with TestClient(TestServer(app)) as client:
        resp = await client.post("/xiaozhi/ota/", json=BODY, headers=HEADERS)
        assert resp.status == 200
        return await resp.json()


async def test_ota_reply_has_websocket_and_no_mqtt(ota, tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    data = await _post(ota.OTAHandler(_config()))
    assert data["websocket"]["url"] == "ws://example.lan:8000/xiaozhi/v1/"
    assert "mqtt" not in data
    assert data["server_time"]["timezone_offset"] == 420
    assert data["firmware"] == {"version": "1.0.0", "url": ""}


async def test_ota_firmware_url_uses_http_base_url(ota, tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "data" / "bin").mkdir(parents=True)
    (tmp_path / "data" / "bin" / "boardx_2.0.0.bin").write_bytes(b"fw")
    data = await _post(ota.OTAHandler(_config(http_base_url="http://nas.lan:9000/")))
    assert data["firmware"]["version"] == "2.0.0"
    assert data["firmware"]["url"] == "http://nas.lan:9000/xiaozhi/ota/download/boardx_2.0.0.bin"


def test_http_base_url_defaults_to_local_ip_and_http_port(ota, monkeypatch):
    monkeypatch.setattr(ota.util, "get_local_ip", lambda: "10.0.0.5")
    assert ota.util.get_http_base_url(_config()) == "http://10.0.0.5:8003"
    assert ota.util.get_http_base_url(_config(http_base_url="http://your_ip_or_domain:port")) == "http://10.0.0.5:8003"


def test_http_server_has_no_vision_route(ota):
    assert not hasattr(ota.SimpleHttpServer(_config()), "vision_handler")
