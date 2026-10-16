"""Subprocess helper for test_connection_db_config.py (not collected by pytest).

Imports core.connection with stubs for the third-party packages that are not installed in every
dev environment (pydub, websockets, ...), builds a ConnectionHandler on a seeded temporary
database, runs _initialize_private_config_async() and prints one JSON line with what happened.
It runs in its own process so the stubs never leak into the other tests.
"""
import asyncio
import importlib.abc
import importlib.machinery
import json
import os
import sqlite3
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

SERVER_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(SERVER_DIR))
os.chdir(SERVER_DIR)

STUB_TOPS = set()


class _Stub(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    def find_spec(self, name, path, target=None):
        if name.split(".")[0] in STUB_TOPS:
            return importlib.machinery.ModuleSpec(name, self, is_package=True)

    def create_module(self, spec):
        m = MagicMock(name=spec.name)
        m.__path__ = []
        m.__spec__ = spec
        m.__name__ = spec.name
        return m

    def exec_module(self, module):
        pass


sys.meta_path.append(_Stub())

import tests.conftest  # noqa: E402,F401  (opus stub, provider mocks)

# Stub whatever is missing, one package at a time
for _ in range(40):
    try:
        import core.connection as conn_module  # noqa: E402
        break
    except ModuleNotFoundError as e:
        STUB_TOPS.add(e.name.split(".")[0])
else:
    raise SystemExit("could not import core.connection")

from core.db import Database, build_base_config, set_database  # noqa: E402
from core.db.seed import seed_database  # noqa: E402
from core.utils.cache.manager import CacheType, cache_manager  # noqa: E402


async def run(db, base, mac):
    handler = conn_module.ConnectionHandler(base, None, None, None, None, None, None)
    handler.loop = asyncio.get_running_loop()
    handler.headers = {"device-id": mac}
    sent = []

    class WS:
        async def send(self, message):
            sent.append(json.loads(message))

        async def close(self, code=None, reason=None):
            sent.append({"closed": code})

    handler.websocket = WS()
    seen = {}

    def fake_initialize_modules(logger, private_config, *flags):
        seen["flags"] = list(flags)
        seen["private_selected"] = private_config.get("selected_module")
        return {}

    with patch.object(conn_module, "initialize_modules", fake_initialize_modules):
        ok = await handler._initialize_private_config_async()
    db.flush()
    return handler, ok, sent, seen


def main():
    tmp = tempfile.mkdtemp()
    db = Database(os.path.join(tmp, "smoke.db"))
    conn = sqlite3.connect(db.path)
    seed_database(conn)
    conn.close()
    set_database(db)
    base = build_base_config(db)
    base["log"] = {"log_dir": tmp, "data_dir": tmp}
    cache_manager.set(CacheType.CONFIG, "main_config", base)  # setup_logging() reads it

    result = {}

    # 1) unknown device, auto_register on (default)
    h, ok, sent, seen = asyncio.run(run(db, base, "AA:BB:CC:00:00:01"))
    row = db.query_one("SELECT agent_id, last_connected_at FROM device WHERE mac = 'aa:bb:cc:00:00:01'")
    result["registered"] = {
        "ok": ok,
        "ready": h.config_ready_event.is_set(),
        "refused": h.device_refused,
        "agent_id": h.agent_id,
        "device_row": [row["agent_id"], bool(row["last_connected_at"])] if row else None,
        "selected_module": h.config["selected_module"],
        "prompt_set": bool(h.config.get("prompt")),
        "chat_history_conf": h.chat_history_conf,
        "plugins": h.config.get("plugins", {}).get("get_weather", {}).get("api_key"),
        "messages": sent,
    }

    # 2) remembered summary comes from the memory table
    db.write_sync("INSERT INTO memory(device_mac, summary, updated_at) VALUES ('aa:bb:cc:00:00:01', 'likes tea', 't')")
    h, ok, sent, seen = asyncio.run(run(db, base, "AA:BB:CC:00:00:01"))
    result["summary_memory"] = h.config.get("summaryMemory")

    # 3) unknown device, auto_register off -> refused and closed with a message
    db.write_sync("UPDATE setting SET value = 'false' WHERE key = 'device.auto_register'")
    h, ok, sent, seen = asyncio.run(run(db, base, "AA:BB:CC:00:00:99"))
    result["refused"] = {
        "ok": ok,
        "ready": h.config_ready_event.is_set(),
        "refused": h.device_refused,
        "messages": sent,
        "device_rows": db.query_one("SELECT COUNT(*) FROM device WHERE mac = 'aa:bb:cc:00:00:99'")[0],
    }
    db.close()
    print("RESULT " + json.dumps(result))


if __name__ == "__main__":
    main()
