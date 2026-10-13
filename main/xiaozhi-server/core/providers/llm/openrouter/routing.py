"""Pure helpers: provider config dict -> OpenRouter SDK request kwargs.

No SDK import and no network, so everything here is unit-testable.
A missing, empty or invalid value always means "do not send".
"""

from config.logger import setup_logging

TAG = __name__
logger = setup_logging()

DEFAULT_BASE_URL = "https://openrouter.ai/api/v1"
DEFAULT_TIMEOUT_SECONDS = 30

PROVIDER_SORTS = ("price", "throughput", "latency")
DATA_COLLECTION_VALUES = ("allow", "deny")
REASONING_EFFORTS = ("max", "xhigh", "high", "medium", "low", "minimal", "none")

_TRUE_STRINGS = ("true", "1", "yes", "y", "on")
_FALSE_STRINGS = ("false", "0", "no", "n", "off")


def parse_list(value):
    """Comma separated string (or list) -> list of non-empty stripped strings."""
    if value is None:
        return []
    if isinstance(value, str):
        items = value.split(",")
    elif isinstance(value, (list, tuple)):
        items = value
    else:
        return []
    result = []
    for item in items:
        text = str(item).strip()
        if text:
            result.append(text)
    return result


def parse_float(value):
    """Tolerant float parsing (console values may be strings). None if invalid."""
    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return None
    try:
        number = float(value)
    except (ValueError, TypeError):
        return None
    if number != number or number in (float("inf"), float("-inf")):
        return None
    return number


def parse_int(value):
    """Tolerant int parsing ("128", 128.0, "128.0"). None if invalid."""
    number = parse_float(value)
    if number is None:
        return None
    return int(number)


def parse_bool(value, default=None):
    """Tolerant bool parsing ("true"/"False"/"1"/0/...). `default` if invalid."""
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    if isinstance(value, (int, float)):
        if value in (0, 1):
            return bool(value)
        return default
    if isinstance(value, str):
        text = value.strip().lower()
        if text in _TRUE_STRINGS:
            return True
        if text in _FALSE_STRINGS:
            return False
    return default


def parse_choice(value, allowed):
    """Lower-cased value if it is one of `allowed`, else None."""
    if not isinstance(value, str):
        return None
    text = value.strip().lower()
    return text if text in allowed else None


def parse_timeout_ms(cfg):
    """`timeout` (seconds, > 0) -> milliseconds, with a default."""
    seconds = parse_float(cfg.get("timeout"))
    if seconds is None or seconds <= 0:
        seconds = DEFAULT_TIMEOUT_SECONDS
    return int(seconds * 1000)


def parse_base_url(cfg):
    base_url = cfg.get("base_url") or cfg.get("url")
    if isinstance(base_url, str) and base_url.strip():
        return base_url.strip()
    return DEFAULT_BASE_URL


def build_sampling_defaults(cfg):
    """Instance level sampling defaults, keyed by SDK argument name."""
    defaults = {}
    for key in ("temperature", "top_p", "frequency_penalty"):
        number = parse_float(cfg.get(key))
        if number is not None:
            defaults[key] = number
    max_tokens = parse_int(cfg.get("max_tokens"))
    if max_tokens is not None and max_tokens > 0:
        defaults["max_completion_tokens"] = max_tokens
    return defaults


def build_provider_preferences(cfg):
    """Config -> `provider` request object (dict). May be empty."""
    provider = {}

    order = parse_list(cfg.get("provider_order"))
    sort = parse_choice(cfg.get("provider_sort"), PROVIDER_SORTS)
    if order:
        provider["order"] = order
        if sort:
            logger.bind(tag=TAG).warning(
                "provider_order is set, provider_sort is ignored"
            )
    elif sort:
        provider["sort"] = sort

    only = parse_list(cfg.get("provider_only"))
    if only:
        provider["only"] = only
    ignore = parse_list(cfg.get("provider_ignore"))
    if ignore:
        provider["ignore"] = ignore

    allow_fallbacks = parse_bool(cfg.get("allow_fallbacks"))
    if allow_fallbacks is not None:
        provider["allow_fallbacks"] = allow_fallbacks

    # Tools need providers that support them, so this defaults to true
    provider["require_parameters"] = parse_bool(
        cfg.get("require_parameters"), default=True
    )

    data_collection = parse_choice(cfg.get("data_collection"), DATA_COLLECTION_VALUES)
    if data_collection:
        provider["data_collection"] = data_collection

    zdr = parse_bool(cfg.get("zdr"))
    if zdr is not None:
        provider["zdr"] = zdr

    for key in ("preferred_max_latency", "preferred_min_throughput"):
        number = parse_float(cfg.get(key))
        if number is not None and number > 0:
            provider[key] = number

    return provider


def build_request_kwargs(cfg):
    """Static (per-instance) kwargs for `chat.send`, excluding model/messages/tools.

    Includes routing (`provider`, `models`), `reasoning_effort`, the routing
    metadata switch and the attribution headers. Sampling defaults are in
    `build_sampling_defaults`.
    """
    kwargs = {}

    fallback_models = parse_list(cfg.get("fallback_models"))
    if fallback_models:
        # `models` is the ordered list of models to try, the primary model first
        primary = cfg.get("model_name")
        models = [primary.strip()] if isinstance(primary, str) and primary.strip() else []
        models += [m for m in fallback_models if m not in models]
        kwargs["models"] = models

    provider = build_provider_preferences(cfg)
    if provider:
        kwargs["provider"] = provider

    reasoning_effort = parse_choice(cfg.get("reasoning_effort"), REASONING_EFFORTS)
    if reasoning_effort:
        kwargs["reasoning_effort"] = reasoning_effort

    # Off by default: the SDK requires several openrouter_metadata fields, so a response that
    # omits one would fail the whole stream. Enable after the live test L10 passes.
    if parse_bool(cfg.get("record_routing"), default=False):
        kwargs["x_open_router_metadata"] = "enabled"

    for cfg_key, sdk_key in (
        ("app_referer", "http_referer"),
        ("app_title", "x_open_router_title"),
        ("app_categories", "x_open_router_categories"),
    ):
        value = cfg.get(cfg_key)
        if isinstance(value, str) and value.strip():
            kwargs[sdk_key] = value.strip()

    return kwargs


def routing_snapshot(request_kwargs):
    """Routing-related subset of the request kwargs, for the usage record."""
    snapshot = {}
    if "models" in request_kwargs:
        snapshot["fallback_models"] = list(request_kwargs["models"])
    if "provider" in request_kwargs:
        snapshot.update(request_kwargs["provider"])
    if "reasoning_effort" in request_kwargs:
        snapshot["reasoning_effort"] = request_kwargs["reasoning_effort"]
    return snapshot
