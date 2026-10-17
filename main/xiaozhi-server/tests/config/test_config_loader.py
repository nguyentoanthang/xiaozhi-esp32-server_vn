"""Tests for the recursive config merge in config/config_loader.py."""
from config.config_loader import merge_configs


def test_merge_simple_override():
    default = {"a": 1, "b": 2}
    custom = {"b": 99}
    assert merge_configs(default, custom) == {"a": 1, "b": 99}


def test_merge_adds_new_key():
    default = {"a": 1}
    custom = {"b": 2}
    assert merge_configs(default, custom) == {"a": 1, "b": 2}


def test_merge_recursive_dict():
    default = {"x": {"a": 1, "b": 2}}
    custom = {"x": {"b": 99}}
    assert merge_configs(default, custom) == {"x": {"a": 1, "b": 99}}


def test_merge_deep_recursive():
    default = {"a": {"b": {"c": 1, "d": 2}}}
    custom = {"a": {"b": {"c": 99}}}
    assert merge_configs(default, custom) == {"a": {"b": {"c": 99, "d": 2}}}


def test_merge_replaces_non_dict_with_dict():
    default = {"a": 1}
    custom = {"a": {"nested": True}}
    assert merge_configs(default, custom) == {"a": {"nested": True}}


def test_merge_replaces_dict_with_non_dict():
    default = {"a": {"nested": True}}
    custom = {"a": 1}
    assert merge_configs(default, custom) == {"a": 1}


def test_merge_does_not_mutate_defaults():
    default = {"a": {"b": 1}}
    custom = {"a": {"c": 2}}
    merge_configs(default, custom)
    assert default == {"a": {"b": 1}}  # unchanged

# ---- data/.config.yaml is optional (first start with an empty ./data) ----------------------------
def _project_without_custom_config(tmp_path, monkeypatch):
    import shutil

    from config import config_loader

    project = tmp_path / "proj"
    (project / "data").mkdir(parents=True)  # an empty mounted ./data
    shutil.copy(config_loader.get_project_dir() + "config.yaml", project / "config.yaml")
    monkeypatch.setattr(config_loader, "get_project_dir", lambda: str(project) + "/")
    monkeypatch.delenv("XIAOZHI_DB", raising=False)
    return project


def test_bootstrap_without_custom_config_uses_defaults(tmp_path, monkeypatch):
    from config.config_loader import load_bootstrap_config

    _project_without_custom_config(tmp_path, monkeypatch)
    boot = load_bootstrap_config()
    assert boot["db"]["path"] == "data/xiaozhi.db"
    assert boot["server"]["port"] == 8000 and boot["server"]["http_port"] == 8003
    assert boot["log"]["log_dir"] == "tmp"


def test_bootstrap_custom_config_overrides_defaults(tmp_path, monkeypatch):
    from config.config_loader import load_bootstrap_config

    project = _project_without_custom_config(tmp_path, monkeypatch)
    (project / "data" / ".config.yaml").write_text("server:\n  port: 9000\n", encoding="utf-8")
    assert load_bootstrap_config()["server"]["port"] == 9000


def test_empty_custom_config_file_is_accepted(tmp_path, monkeypatch):
    from config.config_loader import load_bootstrap_config

    project = _project_without_custom_config(tmp_path, monkeypatch)
    (project / "data" / ".config.yaml").write_text("", encoding="utf-8")
    assert load_bootstrap_config()["db"]["path"] == "data/xiaozhi.db"


def test_check_config_file_does_not_require_custom_config(tmp_path, monkeypatch):
    from config import settings

    _project_without_custom_config(tmp_path, monkeypatch)
    calls = []

    async def fake_load_config():
        calls.append(1)

    monkeypatch.setattr(settings, "load_config", fake_load_config)
    monkeypatch.setattr(settings, "config_file_valid", False)
    settings.check_config_file()  # used to raise FileNotFoundError without data/.config.yaml
    assert calls == [1]
