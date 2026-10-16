"""Setting `tools.server_plugins_enabled` (design section 6a): off by default, no plugin tool reaches the LLM."""
import logging

import pytest

from core.providers.tools.server_plugins import ServerPluginExecutor
from core.providers.tools.unified_tool_manager import ToolManager
from core.providers.tools.base import ToolType
from plugins_func import register as plugin_register
from plugins_func.register import FunctionItem


def _desc(name):
    return {
        "type": "function",
        "function": {
            "name": name,
            "description": f"{name} description",
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
    }


class _Conn:
    def __init__(self, config):
        self.config = config


def _config(enabled=None):
    cfg = {
        "selected_module": {"Intent": "Intent_function_call"},
        "Intent": {"Intent_function_call": {"type": "function_call", "functions": ["fake_weather"]}},
        "plugins": {},
    }
    if enabled is not None:
        cfg["tools"] = {"server_plugins_enabled": enabled}
    return cfg


@pytest.fixture(autouse=True)
def fake_plugins(monkeypatch):
    """Two plugins: one listed in the Intent model, one of the always-on 'necessary' ones."""
    registry = dict(plugin_register.all_function_registry)
    for name in ("fake_weather", "handle_exit_intent"):
        registry[name] = FunctionItem(name, _desc(name), lambda **kw: None, None)
    monkeypatch.setattr(plugin_register, "all_function_registry", registry)
    # The executor module imported the dict by name, so patch its reference too
    import core.providers.tools.server_plugins.plugin_executor as pe

    monkeypatch.setattr(pe, "all_function_registry", registry)
    return registry


def _llm_tool_names(config):
    conn = _Conn(config)
    manager = ToolManager.__new__(ToolManager)  # skip the logger set-up in __init__
    manager.conn = conn
    manager.executors = {}
    manager._cached_tools = None
    manager._cached_function_descriptions = None
    manager.logger = logging.getLogger(__name__)
    manager.executors[ToolType.SERVER_PLUGIN] = ServerPluginExecutor(conn)
    return [d["function"]["name"] for d in manager.get_function_descriptions()]


@pytest.mark.parametrize("config", [_config(), _config(False)])
def test_plugins_off_sends_no_tool_to_the_llm(config):
    # Default (setting missing) and explicit false behave the same
    assert ServerPluginExecutor(_Conn(config)).get_tools() == {}
    assert _llm_tool_names(config) == []


def test_plugins_on_restores_them():
    names = _llm_tool_names(_config(True))
    assert "fake_weather" in names
    assert "handle_exit_intent" in names  # the always-on plugin comes back as well
