"""Offline tests for core/providers/llm/openrouter/routing.py (pure functions)."""


from core.providers.llm.openrouter import routing


def test_defaults_send_only_required_parameters():
    kwargs = routing.build_request_kwargs({"model_name": "openai/gpt-4o-mini"})
    assert kwargs == {"provider": {"require_parameters": True}}


def test_record_routing_true_requests_metadata():
    for value in (True, "true"):
        kwargs = routing.build_request_kwargs({"record_routing": value})
        assert kwargs["x_open_router_metadata"] == "enabled"


def test_all_keys_map_to_sdk_kwargs():
    cfg = {
        "model_name": "a/primary",
        "fallback_models": "b/one, c/two ,, a/primary",
        "provider_order": "DeepInfra, Together",
        "provider_only": "DeepInfra,Together,Fireworks",
        "provider_ignore": "Azure",
        "allow_fallbacks": "false",
        "require_parameters": False,
        "data_collection": "DENY",
        "zdr": "true",
        "preferred_max_latency": "1.5",
        "preferred_min_throughput": 40,
        "reasoning_effort": "Low",
        "record_routing": "false",
        "app_referer": "https://example.com",
        "app_title": "Xiaozhi",
        "app_categories": "voice,cli-agent",
    }
    kwargs = routing.build_request_kwargs(cfg)
    assert kwargs["models"] == ["a/primary", "b/one", "c/two"]
    assert kwargs["provider"] == {
        "order": ["DeepInfra", "Together"],
        "only": ["DeepInfra", "Together", "Fireworks"],
        "ignore": ["Azure"],
        "allow_fallbacks": False,
        "require_parameters": False,
        "data_collection": "deny",
        "zdr": True,
        "preferred_max_latency": 1.5,
        "preferred_min_throughput": 40.0,
    }
    assert kwargs["reasoning_effort"] == "low"
    assert "x_open_router_metadata" not in kwargs
    assert kwargs["http_referer"] == "https://example.com"
    assert kwargs["x_open_router_title"] == "Xiaozhi"
    assert kwargs["x_open_router_categories"] == "voice,cli-agent"


def test_sort_is_sent_without_order():
    provider = routing.build_provider_preferences({"provider_sort": "Latency"})
    assert provider["sort"] == "latency"


def test_order_beats_sort_with_warning(monkeypatch):
    warnings = []

    class FakeLogger:
        def bind(self, **_kw):
            return self

        def warning(self, msg):
            warnings.append(msg)

    monkeypatch.setattr(routing, "logger", FakeLogger())
    provider = routing.build_provider_preferences(
        {"provider_order": "A,B", "provider_sort": "price"}
    )
    assert "sort" not in provider
    assert provider["order"] == ["A", "B"]
    assert len(warnings) == 1


def test_invalid_and_empty_values_are_dropped():
    cfg = {
        "provider_sort": "fastest",
        "provider_order": "  ,  ",
        "data_collection": "maybe",
        "zdr": "perhaps",
        "allow_fallbacks": "",
        "preferred_max_latency": "abc",
        "preferred_min_throughput": -3,
        "reasoning_effort": "ultra",
        "fallback_models": "",
        "app_referer": "   ",
    }
    kwargs = routing.build_request_kwargs(cfg)
    assert kwargs == {"provider": {"require_parameters": True}}


def test_require_parameters_invalid_falls_back_to_default_true():
    assert routing.build_provider_preferences({"require_parameters": "??"})[
        "require_parameters"
    ] is True


def test_parse_list():
    assert routing.parse_list(None) == []
    assert routing.parse_list("a, b ,,c") == ["a", "b", "c"]
    assert routing.parse_list(["x", " y ", ""]) == ["x", "y"]
    assert routing.parse_list(5) == []


def test_parse_numbers_and_bools():
    assert routing.parse_float("0.7") == 0.7
    assert routing.parse_float(True) is None
    assert routing.parse_float("") is None
    assert routing.parse_float("nan") is None
    assert routing.parse_int("128.0") == 128
    assert routing.parse_int("x") is None
    assert routing.parse_bool("TRUE") is True
    assert routing.parse_bool("off") is False
    assert routing.parse_bool(1) is True
    assert routing.parse_bool(7, default="d") == "d"
    assert routing.parse_bool(None, default=True) is True


def test_sampling_defaults():
    cfg = {"temperature": "0.3", "top_p": 0.9, "frequency_penalty": "", "max_tokens": "256"}
    assert routing.build_sampling_defaults(cfg) == {
        "temperature": 0.3,
        "top_p": 0.9,
        "max_completion_tokens": 256,
    }
    assert routing.build_sampling_defaults({"max_tokens": 0}) == {}


def test_timeout_and_base_url():
    assert routing.parse_timeout_ms({}) == 30000
    assert routing.parse_timeout_ms({"timeout": "12.5"}) == 12500
    assert routing.parse_timeout_ms({"timeout": -1}) == 30000
    assert routing.parse_base_url({}) == routing.DEFAULT_BASE_URL
    assert routing.parse_base_url({"base_url": " http://x/v1 "}) == "http://x/v1"


def test_routing_snapshot():
    kwargs = routing.build_request_kwargs(
        {"model_name": "a", "fallback_models": "b", "provider_sort": "price"}
    )
    snap = routing.routing_snapshot(kwargs)
    assert snap["fallback_models"] == ["a", "b"]
    assert snap["sort"] == "price"
