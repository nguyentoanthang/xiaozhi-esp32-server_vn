"""Guardrails: mask personal data in USER text before it goes anywhere else.

See docs/minimal-server-design.md, section 6c. Emails, card numbers (Luhn checked), phone numbers
(Vietnamese and international) and names from the `guardrail_name` table are replaced by numbered
placeholders ([EMAIL_1], [CARD_1], [PHONE_1], [NAME_1]). The same value gets the same number for the
lifetime of one Guardrail object (one connection). LLM replies are never inspected.

Pure Python (standard library only) so it can be unit tested without the server.
"""

import json
import re
import unicodedata
from typing import Any, Dict, Iterable, List, Optional, Tuple

TYPES = ("EMAIL", "CARD", "PHONE", "NAME")

# A placeholder produced by this module; text between placeholders is the only text we scan again
_PLACEHOLDER_RE = re.compile(r"\[(?:EMAIL|CARD|PHONE|NAME)_\d+\]")
_RESTORE_RE = re.compile(r"\[(EMAIL|CARD|PHONE|NAME)_(\d+)\]")

_EMAIL_RE = re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+")
# A run of 13+ digits with one optional space or dash between digits; _sub_card finds the card inside it
_CARD_RUN_RE = re.compile(r"(?<!\d)\d(?:[ \-]?\d){12,}")
_DIGITS_RE = re.compile(r"\d+")
# International: '+' then 8-15 digits, up to two separator characters (space . - parentheses) between digits
_PHONE_INTL_RE = re.compile(r"(?<![\d+])\+\d(?:[\s.\-()]{0,2}\d){7,14}(?!\d)")
# Vietnamese national format: 0 + 9 digits (mobile) or 10 digits (landline with area code),
# optional space/dot/dash between digits
_PHONE_VN_RE = re.compile(r"(?<![\d+])0(?:[\s.\-]?\d){9,10}(?!\d)")


def luhn_valid(digits: str) -> bool:
    """Luhn checksum of a digit string."""
    total = 0
    for i, ch in enumerate(reversed(digits)):
        d = ord(ch) - 48
        if i % 2 == 1:
            d *= 2
            if d > 9:
                d -= 9
        total += d
    return total % 10 == 0


def _is_cjk(ch: str) -> bool:
    return ord(ch) >= 0x2E80


def _name_pattern(names: Iterable[str]) -> Optional["re.Pattern[str]"]:
    """One regex for all names: longest first, whole word, case-insensitive, flexible spaces."""
    cleaned = {unicodedata.normalize("NFC", n).strip() for n in names if n and n.strip()}
    if not cleaned:
        return None
    parts = []
    for name in sorted(cleaned, key=len, reverse=True):
        body = r"\s+".join(re.escape(piece) for piece in name.split())
        # Whole word; no boundary against CJK text, which has no spaces between words
        left = "" if _is_cjk(name[0]) else r"(?<!\w)"
        right = "" if _is_cjk(name[-1]) else r"(?!\w)"
        parts.append(f"{left}{body}{right}")
    return re.compile("|".join(parts), re.IGNORECASE)


class Guardrail:
    """Masks user text for one connection and remembers the placeholder numbering."""

    def __init__(
        self,
        enabled: bool = True,
        mask_email: bool = True,
        mask_phone: bool = True,
        mask_card: bool = True,
        mask_name: bool = True,
        restore_in_reply: bool = False,
        names: Iterable[str] = (),
    ):
        self.enabled = enabled
        self.mask_email = mask_email
        self.mask_phone = mask_phone
        self.mask_card = mask_card
        self.mask_name = mask_name
        self.restore_in_reply = restore_in_reply
        self._name_re = _name_pattern(names) if mask_name else None
        self._numbers: Dict[str, Dict[str, int]] = {t: {} for t in TYPES}
        self._originals: Dict[str, str] = {}  # '[PHONE_1]' -> first text seen

    @classmethod
    def from_config(cls, config: Dict[str, Any], names: Optional[Iterable[str]] = None) -> "Guardrail":
        """Build from the nested config dict (`guardrails.*` settings). Missing keys default to on,
        except restore_in_reply (off)."""
        g = (config or {}).get("guardrails") or {}
        return cls(
            enabled=bool(g.get("enabled", True)),
            mask_email=bool(g.get("mask_email", True)),
            mask_phone=bool(g.get("mask_phone", True)),
            mask_card=bool(g.get("mask_card", True)),
            mask_name=bool(g.get("mask_name", True)),
            restore_in_reply=bool(g.get("restore_in_reply", False)),
            names=names or (),
        )

    # ------------------------------------------------------------- numbering

    def _placeholder(self, kind: str, key: str, original: str) -> str:
        numbers = self._numbers[kind]
        n = numbers.get(key)
        if n is None:
            n = numbers[key] = len(numbers) + 1
        placeholder = f"[{kind}_{n}]"
        self._originals.setdefault(placeholder, original)
        return placeholder

    # ---------------------------------------------------------------- masking

    def _sub_email(self, m: "re.Match[str]") -> str:
        return self._placeholder("EMAIL", m.group(0).lower(), m.group(0))

    def _sub_card(self, m: "re.Match[str]") -> str:
        """Mask the longest group-aligned span of 13-19 digits that passes Luhn; keep the rest.

        Looking inside the run (not only at the whole run) catches a card number written right
        after another number ("0912345678 4111 1111 1111 1111").
        """
        run = m.group(0)
        tokens = list(_DIGITS_RE.finditer(run))
        out: List[str] = []
        pos, i = 0, 0
        while i < len(tokens):
            found = None
            for j in range(len(tokens) - 1, i - 1, -1):
                digits = "".join(t.group(0) for t in tokens[i:j + 1])
                if 13 <= len(digits) <= 19 and luhn_valid(digits):
                    found = (j, digits)
                    break
            if found is None:
                i += 1
                continue
            j, digits = found
            start, end = tokens[i].start(), tokens[j].end()
            out.append(run[pos:start])
            out.append(self._placeholder("CARD", digits, run[start:end]))
            pos, i = end, j + 1
        out.append(run[pos:])
        return "".join(out)

    def _sub_phone(self, m: "re.Match[str]") -> str:
        text = m.group(0)
        digits = re.sub(r"\D", "", text)
        # +84 912 345 678 and 0912 345 678 are the same number
        if text.startswith("+84"):
            digits = "0" + digits[2:]
        return self._placeholder("PHONE", digits, text)

    def _sub_name(self, m: "re.Match[str]") -> str:
        return self._placeholder("NAME", " ".join(m.group(0).split()).casefold(), m.group(0))

    @staticmethod
    def _outside_placeholders(text: str, pattern: "re.Pattern[str]", repl) -> str:
        """Apply pattern.sub only to the text between placeholders, so a placeholder is never re-masked."""
        out: List[str] = []
        pos = 0
        for m in _PLACEHOLDER_RE.finditer(text):
            out.append(pattern.sub(repl, text[pos:m.start()]))
            out.append(m.group(0))
            pos = m.end()
        out.append(pattern.sub(repl, text[pos:]))
        return "".join(out)

    def mask(self, text: str) -> str:
        """Mask plain text. Order: email, card, phone, name."""
        if not self.enabled or not text or not isinstance(text, str):
            return text
        text = unicodedata.normalize("NFC", text)
        steps: List[Tuple[bool, Any, Any]] = [
            (self.mask_email, _EMAIL_RE, self._sub_email),
            (self.mask_card, _CARD_RUN_RE, self._sub_card),
            (self.mask_phone, _PHONE_INTL_RE, self._sub_phone),
            (self.mask_phone, _PHONE_VN_RE, self._sub_phone),
            (self._name_re is not None, self._name_re, self._sub_name),
        ]
        for active, pattern, repl in steps:
            if active:
                text = self._outside_placeholders(text, pattern, repl)
        return text

    def mask_asr_result(self, raw: Any) -> Any:
        """Mask what an ASR provider returned: plain text, a dict with `content`, or its JSON string.

        The type is preserved. Only the `content` field of the JSON forms is touched.
        """
        if not self.enabled or not raw:
            return raw
        if isinstance(raw, dict):
            if isinstance(raw.get("content"), str):
                raw = dict(raw)
                raw["content"] = self.mask(raw["content"])
            return raw
        if isinstance(raw, str):
            stripped = raw.strip()
            if stripped.startswith("{") and stripped.endswith("}"):
                try:
                    data = json.loads(stripped)
                except (json.JSONDecodeError, ValueError):
                    data = None
                if isinstance(data, dict) and isinstance(data.get("content"), str):
                    data["content"] = self.mask(data["content"])
                    return json.dumps(data, ensure_ascii=False)
            return self.mask(raw)
        return raw

    # ---------------------------------------------------------------- restore

    def restore(self, text: str) -> str:
        """Put real values back (text for the TTS only). No-op unless restore_in_reply is on."""
        if not self.enabled or not self.restore_in_reply or not text or not self._originals:
            return text
        return _RESTORE_RE.sub(lambda m: self._originals.get(m.group(0), m.group(0)), text)
