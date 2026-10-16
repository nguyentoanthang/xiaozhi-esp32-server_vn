"""SQLite data layer (config, agents, devices, later chat history and usage).

Standard library only; safe to import before the logger or any heavy server module.
"""

from core.db.database import (
    Database,
    close_database,
    get_database,
    resolve_db_path,
    set_database,
    utcnow_iso,
)
from core.db.config_assembly import (
    DeviceRefused,
    NoDefaultAgent,
    build_agent_config,
    build_base_config,
    build_global_config,
    get_agent_config,
    get_setting,
    touch_device,
)

__all__ = [
    "Database",
    "DeviceRefused",
    "NoDefaultAgent",
    "build_agent_config",
    "build_base_config",
    "build_global_config",
    "close_database",
    "get_agent_config",
    "get_database",
    "get_setting",
    "resolve_db_path",
    "set_database",
    "touch_device",
    "utcnow_iso",
]
