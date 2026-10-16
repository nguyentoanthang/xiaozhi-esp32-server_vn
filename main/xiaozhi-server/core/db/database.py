"""SQLite access layer: per-thread read connections and one process-wide writer thread.

Only the standard library is imported here on purpose, so the module can be used before the
logger or any heavy server module is loaded.

Rules (see docs/minimal-server-design.md, "Database access rules"):
- Reads use one connection per thread, so async code calls them through asyncio.to_thread.
- Writes go through a queue consumed by ONE writer thread, which avoids "database is locked".
- A failing write is logged and never raised into the conversation.
"""

import asyncio
import os
import queue
import sqlite3
import threading
from concurrent.futures import Future
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Iterable, List, Optional, Sequence

try:  # loguru is what the rest of the server uses; fall back to stdlib logging when absent
    from loguru import logger as _loguru_logger

    def _log(level: str, msg: str):
        getattr(_loguru_logger.bind(tag=TAG), level)(msg)

except Exception:  # pragma: no cover - loguru is a normal dependency of the server
    import logging

    _std_logger = logging.getLogger("xiaozhi.db")

    def _log(level: str, msg: str):
        getattr(_std_logger, "warning" if level == "warning" else level)(msg)


TAG = "core.db.database"

SCHEMA_VERSION = 1
SCHEMA_FILE = Path(__file__).with_name("schema.sql")
# core/db -> core -> xiaozhi-server
PROJECT_DIR = Path(__file__).resolve().parent.parent.parent
DEFAULT_DB_PATH = "data/xiaozhi.db"
DB_ENV_VAR = "XIAOZHI_DB"

_STOP = object()


def utcnow_iso() -> str:
    """Current time as ISO-8601 UTC text, the timestamp format used in every table."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def resolve_db_path(path: Optional[str] = None) -> str:
    """Resolve the database path: explicit argument, then env XIAOZHI_DB, then the default.

    A relative path is taken relative to the xiaozhi-server directory (not the working directory).
    """
    raw = path or os.environ.get(DB_ENV_VAR) or DEFAULT_DB_PATH
    if raw == ":memory:" or raw.startswith("file:"):
        return raw
    p = Path(raw)
    if not p.is_absolute():
        p = PROJECT_DIR / p
    return str(p)


def open_connection(path: str, *, read_only: bool = False) -> sqlite3.Connection:
    """Open a connection with the standard pragmas applied."""
    if path not in (":memory:",) and not path.startswith("file:"):
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    conn = sqlite3.connect(
        path,
        timeout=5.0,
        check_same_thread=False,  # connections are only ever used by their owner thread; this allows close() at shutdown
        uri=path.startswith("file:"),
    )
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA busy_timeout = 5000")
    conn.execute("PRAGMA foreign_keys = ON")
    if not read_only:
        conn.execute("PRAGMA journal_mode = WAL")
        conn.execute("PRAGMA synchronous = NORMAL")
    else:
        conn.execute("PRAGMA query_only = ON")
    return conn


def apply_schema(conn: sqlite3.Connection) -> None:
    """Apply schema.sql. Idempotent: every statement is CREATE ... IF NOT EXISTS."""
    current = conn.execute("PRAGMA user_version").fetchone()[0]
    if current >= SCHEMA_VERSION:
        # Already at (or past) this version; the IF NOT EXISTS statements would be no-ops
        return
    conn.executescript(SCHEMA_FILE.read_text(encoding="utf-8"))


class Database:
    """One SQLite file, many reader connections (one per thread), one writer thread."""

    def __init__(self, path: Optional[str] = None):
        self.path = resolve_db_path(path)
        self._local = threading.local()
        self._readers: List[sqlite3.Connection] = []
        self._readers_lock = threading.Lock()
        self._queue: "queue.Queue[Any]" = queue.Queue()
        self._writer: Optional[threading.Thread] = None
        self._writer_lock = threading.Lock()
        self._closed = False

        # Create the file and apply the schema once, before any reader or writer exists
        conn = open_connection(self.path)
        try:
            apply_schema(conn)
        finally:
            conn.close()

    # ---------------------------------------------------------------- reads

    def _reader(self) -> sqlite3.Connection:
        conn = getattr(self._local, "conn", None)
        if conn is None:
            if self._closed:
                raise RuntimeError("Database is closed")
            conn = open_connection(self.path, read_only=True)
            self._local.conn = conn
            with self._readers_lock:
                self._readers.append(conn)
        return conn

    def query_all(self, sql: str, params: Sequence[Any] = ()) -> List[sqlite3.Row]:
        """Run a SELECT on the calling thread's connection."""
        return self._reader().execute(sql, params).fetchall()

    def query_one(self, sql: str, params: Sequence[Any] = ()) -> Optional[sqlite3.Row]:
        return self._reader().execute(sql, params).fetchone()

    async def aquery_all(self, sql: str, params: Sequence[Any] = ()) -> List[sqlite3.Row]:
        return await asyncio.to_thread(self.query_all, sql, params)

    async def aquery_one(self, sql: str, params: Sequence[Any] = ()) -> Optional[sqlite3.Row]:
        return await asyncio.to_thread(self.query_one, sql, params)

    # --------------------------------------------------------------- writes

    def _ensure_writer(self):
        with self._writer_lock:
            if self._closed:
                raise RuntimeError("Database is closed")
            if self._writer is None or not self._writer.is_alive():
                self._writer = threading.Thread(
                    target=self._writer_loop, name="xiaozhi-db-writer", daemon=True
                )
                self._writer.start()

    def _writer_loop(self):
        conn = open_connection(self.path)
        try:
            while True:
                item = self._queue.get()
                if item is _STOP:
                    self._queue.task_done()
                    break
                fn, future = item
                try:
                    result = fn(conn)
                    conn.commit()
                    if future is not None:
                        future.set_result(result)
                except Exception as e:
                    # A failed write is logged and never propagates into a conversation
                    try:
                        conn.rollback()
                    except Exception:
                        pass
                    _log("error", f"Database write failed: {e!r}")
                    if future is not None:
                        future.set_exception(e)
                finally:
                    self._queue.task_done()
        finally:
            conn.close()

    def submit(self, fn: Callable[[sqlite3.Connection], Any]) -> Future:
        """Queue fn(conn) on the writer thread. The transaction is committed after fn returns.

        Returns a Future that holds the result or the exception. Callers that do not care
        (chat rows, usage, ...) simply ignore it; the failure is logged by the writer anyway.
        """
        future: Future = Future()
        try:
            self._ensure_writer()
        except RuntimeError as e:
            _log("error", f"Database write dropped: {e}")
            future.set_exception(e)
            return future
        self._queue.put((fn, future))
        return future

    def write(self, sql: str, params: Sequence[Any] = ()) -> Future:
        """Queue one INSERT/UPDATE/DELETE statement."""
        return self.submit(lambda conn: conn.execute(sql, params).rowcount)

    def write_many(self, sql: str, rows: Iterable[Sequence[Any]]) -> Future:
        return self.submit(lambda conn: conn.executemany(sql, list(rows)).rowcount)

    def insert(self, sql: str, params: Sequence[Any] = ()) -> Future:
        """Queue an INSERT; the Future resolves to cursor.lastrowid."""
        return self.submit(lambda conn: conn.execute(sql, params).lastrowid)

    def write_sync(self, sql: str, params: Sequence[Any] = (), timeout: float = 10.0) -> bool:
        """Queue a statement and wait for it. Returns False (and logs) on failure, never raises."""
        return self.wait(self.write(sql, params), timeout)

    @staticmethod
    def wait(future: Future, timeout: float = 10.0) -> bool:
        """Wait for a write Future. True on success, False on failure or timeout."""
        try:
            future.result(timeout)
            return True
        except Exception as e:
            _log("warning", f"Database write did not complete: {e!r}")
            return False

    async def awrite(self, sql: str, params: Sequence[Any] = ()) -> bool:
        return await asyncio.to_thread(self.write_sync, sql, params)

    def flush(self, timeout: float = 10.0) -> bool:
        """Wait until everything queued so far has been written."""
        if self._writer is None:
            return True
        return self.wait(self.submit(lambda conn: None), timeout)

    # ------------------------------------------------------------- shutdown

    def close(self, timeout: float = 10.0):
        """Drain the write queue, stop the writer thread and close every connection."""
        with self._writer_lock:
            if self._closed:
                return
            writer = self._writer
            if writer is not None and writer.is_alive():
                self._queue.put(_STOP)
            self._closed = True
        if writer is not None:
            writer.join(timeout)
            if writer.is_alive():
                _log("warning", "Database writer thread did not stop in time")
        with self._readers_lock:
            readers, self._readers = self._readers, []
        for conn in readers:
            try:
                conn.close()
            except Exception:
                pass
        self._local = threading.local()


# ------------------------------------------------------------ process singleton

_instance: Optional[Database] = None
_instance_lock = threading.Lock()


def get_database(path: Optional[str] = None) -> Database:
    """The process-wide Database. The first call decides the path; later calls reuse it."""
    global _instance
    with _instance_lock:
        if _instance is None or _instance._closed:
            _instance = Database(path)
        return _instance


def set_database(db: Optional[Database]) -> None:
    """Replace the process-wide instance (tests, or a different path at startup)."""
    global _instance
    with _instance_lock:
        _instance = db


def close_database() -> None:
    global _instance
    with _instance_lock:
        db, _instance = _instance, None
    if db is not None:
        db.close()
