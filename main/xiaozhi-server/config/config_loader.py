import os
import asyncio
import yaml
from collections.abc import Mapping


def get_project_dir():
    """Get the project root directory"""
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/"


def read_config(config_path):
    with open(config_path, "r", encoding="utf-8") as file:
        config = yaml.safe_load(file)
    return config


# Keys of data/.config.yaml that are needed before the database can be opened.
# Everything else comes from the SQLite database (see docs/minimal-server-design.md, "Bootstrap").
BOOTSTRAP_SERVER_KEYS = ("ip", "port", "http_port", "auth_key")


def load_bootstrap_config():
    """Read the bootstrap settings: db.path, the log block and server ip/port/http_port.

    Defaults come from config.yaml, data/.config.yaml overrides them, and the env var
    XIAOZHI_DB overrides db.path.
    """
    default_config = read_config(get_project_dir() + "config.yaml") or {}
    custom_path = get_project_dir() + "data/.config.yaml"
    custom_config = read_config(custom_path) if os.path.exists(custom_path) else {}
    custom_config = custom_config or {}

    bootstrap = {
        "db": {"path": "data/xiaozhi.db"},
        "log": dict(default_config.get("log") or {}),
        "server": {
            k: v
            for k, v in (default_config.get("server") or {}).items()
            if k in BOOTSTRAP_SERVER_KEYS
        },
    }
    bootstrap = merge_configs(
        bootstrap,
        {
            "db": custom_config.get("db") or {},
            "log": custom_config.get("log") or {},
            "server": {
                k: v
                for k, v in (custom_config.get("server") or {}).items()
                if k in BOOTSTRAP_SERVER_KEYS
            },
        },
    )
    env_path = os.environ.get("XIAOZHI_DB")
    if env_path:
        bootstrap["db"]["path"] = env_path
    return bootstrap


def get_config_database(bootstrap=None):
    """Open (or reuse) the process-wide database named by the bootstrap settings."""
    from core.db import get_database

    bootstrap = bootstrap or load_bootstrap_config()
    return get_database(bootstrap["db"]["path"])


def _build_config_from_db(bootstrap):
    """Blocking: global settings + default agent models, with the bootstrap values on top."""
    from core.db import build_base_config

    from core.db.seed import ensure_seeded

    db = get_config_database(bootstrap)
    ensure_seeded(db)  # first start: fill an empty database; a seeded one is left alone
    config = build_base_config(db)
    server = config.setdefault("server", {})
    server.update(bootstrap["server"])
    config["log"] = bootstrap["log"]
    config["db"] = {"path": db.path}
    # Always true in this build: config, agents and devices come from SQLite
    config["db_enabled"] = True
    return config


async def load_config_from_db(bootstrap=None):
    """Build the server config from the database (runs the queries in a worker thread)."""
    bootstrap = bootstrap or load_bootstrap_config()
    return await asyncio.to_thread(_build_config_from_db, bootstrap)


async def load_config():
    """Load the configuration: bootstrap file + database"""
    from core.utils.cache.manager import cache_manager, CacheType

    # Check the cache
    cached_config = cache_manager.get(CacheType.CONFIG, "main_config")
    if cached_config is not None:
        return cached_config

    config = await load_config_from_db()
    # Initialize directories
    ensure_directories(config)

    # Cache the config
    cache_manager.set(CacheType.CONFIG, "main_config", config)
    return config


async def get_private_config(config, device_id):
    """Per-device config (agent models, prompt, memory, ...) from the database.

    Raises core.db.DeviceRefused for an unknown device when device.auto_register is off.
    """
    from core.db import get_agent_config, get_database

    # The process-wide instance was opened by load_config()
    return await get_agent_config(get_database(), device_id)


def ensure_directories(config):
    """Ensure all configured paths exist"""
    dirs_to_create = set()
    project_dir = get_project_dir()  # Get the project root directory
    # Log file directory
    log_dir = config.get("log", {}).get("log_dir", "tmp")
    dirs_to_create.add(os.path.join(project_dir, log_dir))

    # ASR/TTS module output directories
    for module in ["ASR", "TTS"]:
        if config.get(module) is None:
            continue
        for provider in config.get(module, {}).values():
            output_dir = provider.get("output_dir", "")
            if output_dir:
                dirs_to_create.add(output_dir)

    # Create model directories based on selected_module
    selected_modules = config.get("selected_module", {})
    for module_type in ["ASR", "LLM", "TTS"]:
        selected_provider = selected_modules.get(module_type)
        if not selected_provider:
            continue
        if config.get(module_type) is None:
            continue
        if config.get(selected_provider) is None:
            continue
        provider_config = config.get(module_type, {}).get(selected_provider, {})
        output_dir = provider_config.get("output_dir")
        if output_dir:
            full_model_dir = os.path.join(project_dir, output_dir)
            dirs_to_create.add(full_model_dir)

    # Create the directories in one place (keeps the original data directory creation)
    for dir_path in dirs_to_create:
        try:
            os.makedirs(dir_path, exist_ok=True)
        except PermissionError:
            print(f"Warning: unable to create directory {dir_path}, please check write permissions")


def merge_configs(default_config, custom_config):
    """
    Recursively merge configs; custom_config has higher priority

    Args:
        default_config: Default config
        custom_config: User-defined config

    Returns:
        The merged config
    """
    if not isinstance(default_config, Mapping) or not isinstance(
        custom_config, Mapping
    ):
        return custom_config

    merged = dict(default_config)

    for key, value in custom_config.items():
        if (
            key in merged
            and isinstance(merged[key], Mapping)
            and isinstance(value, Mapping)
        ):
            merged[key] = merge_configs(merged[key], value)
        else:
            merged[key] = value

    return merged
