"""Fixtures for the SQLite layer tests (real files under tmp_path; the layer is stdlib-only)."""
import pytest

from core.db.database import Database
from core.db.seed import seed_database


@pytest.fixture
def db(tmp_path):
    database = Database(str(tmp_path / "test.db"))
    yield database
    database.close()


@pytest.fixture
def seeded_db(db):
    import sqlite3

    conn = sqlite3.connect(db.path)
    try:
        seed_database(conn)
    finally:
        conn.close()
    return db
