"""Guardrails: masking personal data in user text (pure functions, no server needed)."""
import json

from core.utils.guardrails import Guardrail, luhn_valid

VISA = "4111 1111 1111 1111"  # Luhn valid test number
VISA_DASH = "4111-1111-1111-1111"


def g(**kw):
    return Guardrail(**kw)


# ------------------------------------------------------------------ email

def test_email_is_masked():
    assert g().mask("write to John.Doe+x@Example.co.uk please") == "write to [EMAIL_1] please"


def test_same_email_same_number_other_email_next_number():
    out = g().mask("a@b.com then c@d.org then A@B.com")
    assert out == "[EMAIL_1] then [EMAIL_2] then [EMAIL_1]"


# ------------------------------------------------------------------- card

def test_luhn():
    assert luhn_valid("4111111111111111")
    assert not luhn_valid("4111111111111112")


def test_card_with_spaces_and_dashes_is_masked():
    assert g().mask(f"my card is {VISA} ok") == "my card is [CARD_1] ok"
    assert g().mask(f"card {VISA_DASH}.") == "card [CARD_1]."
    assert g().mask("4111111111111111") == "[CARD_1]"


def test_card_rejects_numbers_that_fail_luhn():
    text = "order 4111 1111 1111 1112 shipped"
    assert g().mask(text) == text


def test_card_length_bounds():
    assert g().mask("378282246310005") == "[CARD_1]"  # 15 digits (Amex test number)
    short = "411111111111"  # 12 digits
    assert g().mask(short) == short


def test_card_is_not_taken_for_a_phone_number():
    out = g().mask(f"{VISA} and 0912 345 678")
    assert out == "[CARD_1] and [PHONE_1]"


# ------------------------------------------------------------------ phone

def test_vietnamese_phone_formats():
    for number in ("0912345678", "0912 345 678", "0912.345.678", "091-234-5678", "+84 912 345 678", "+84912345678"):
        assert g().mask(f"call {number} now") == "call [PHONE_1] now", number


def test_vietnamese_landline_and_international():
    assert g().mask("0283 822 1234") == "[PHONE_1]"
    assert g().mask("+1 (555) 123-4567") == "[PHONE_1]"
    assert g().mask("+44 20 7946 0958") == "[PHONE_1]"


def test_same_phone_in_different_formats_gets_the_same_number():
    out = g().mask("0912345678, +84 912 345 678, 0987654321")
    assert out == "[PHONE_1], [PHONE_1], [PHONE_2]"


def test_short_numbers_and_years_are_not_phones():
    for text in ("in 2024 we met", "room 0123", "it costs 120000 dong", "call 112", "0912 34"):
        assert g().mask(text) == text


# ------------------------------------------------------------------- name

def test_name_whole_word_case_insensitive():
    gr = g(names=["Thang", "Linh"])
    assert gr.mask("Hi thang, I am LINH") == "Hi [NAME_1], I am [NAME_2]"


def test_name_boundaries():
    gr = g(names=["Ann"])
    assert gr.mask("Annie and Joanna met Ann.") == "Annie and Joanna met [NAME_1]."
    assert gr.mask("Ann's book") == "[NAME_1]'s book"


def test_name_longest_first_and_multiword():
    gr = g(names=["Anna", "Anna Maria", "Nguyen Van A"])
    assert gr.mask("Anna Maria said hi to Anna") == "[NAME_1] said hi to [NAME_2]"
    assert gr.mask("nguyen   van a is here") == "[NAME_3] is here"


def test_name_with_vietnamese_diacritics_and_unicode_normalisation():
    import unicodedata

    gr = g(names=["Thắng"])
    nfd = unicodedata.normalize("NFD", "Chào Thắng nhé")
    assert gr.mask(nfd) == "Chào [NAME_1] nhé"
    assert gr.mask("thắng") == "[NAME_1]"


def test_same_name_different_case_same_number():
    gr = g(names=["Linh"])
    assert gr.mask("Linh linh LINH") == "[NAME_1] [NAME_1] [NAME_1]"


def test_empty_name_list_masks_no_names():
    assert g(names=[]).mask("Hello Thang") == "Hello Thang"
    assert g(names=["", "  "]).mask("Hello Thang") == "Hello Thang"


def test_name_does_not_match_inside_a_placeholder():
    gr = g(names=["email", "phone"])
    out = gr.mask("a@b.com 0912345678")
    assert out == "[EMAIL_1] [PHONE_1]"


# ------------------------------------------------------------ order, mixes

def test_all_types_in_one_text():
    gr = g(names=["Linh"])
    out = gr.mask(f"Linh: mail linh@x.vn, tel 0912345678, card {VISA}")
    assert out == "[NAME_1]: mail [EMAIL_1], tel [PHONE_1], card [CARD_1]"


def test_email_containing_a_name_is_masked_as_one_email():
    gr = g(names=["linh"])
    assert gr.mask("linh@x.vn") == "[EMAIL_1]"


def test_numbering_continues_across_calls():
    gr = g()
    assert gr.mask("a@b.com") == "[EMAIL_1]"
    assert gr.mask("c@d.com and a@b.com") == "[EMAIL_2] and [EMAIL_1]"


# --------------------------------------------------------------- switches

def test_master_switch_off_masks_nothing():
    text = f"a@b.com 0912345678 {VISA}"
    gr = g(enabled=False, names=["Linh"])
    assert gr.mask(text) == text
    assert gr.mask_asr_result({"content": text}) == {"content": text}


def test_per_type_switches():
    text = f"a@b.com 0912345678 {VISA} Linh"
    assert g(mask_email=False, names=["Linh"]).mask(text) == f"a@b.com [PHONE_1] [CARD_1] [NAME_1]"
    assert g(mask_phone=False, names=["Linh"]).mask(text) == f"[EMAIL_1] 0912345678 [CARD_1] [NAME_1]"
    assert g(mask_card=False, names=["Linh"]).mask(text) == f"[EMAIL_1] [PHONE_1] {VISA} [NAME_1]"
    assert g(mask_name=False, names=["Linh"]).mask(text) == f"[EMAIL_1] [PHONE_1] [CARD_1] Linh"


def test_from_config_reads_the_guardrails_block():
    cfg = {"guardrails": {"enabled": True, "mask_phone": False, "mask_name": True, "restore_in_reply": True}}
    gr = Guardrail.from_config(cfg, names=["Linh"])
    assert gr.mask("Linh 0912345678") == "[NAME_1] 0912345678"
    assert gr.restore_in_reply is True
    # Missing block: everything on, restore off
    default = Guardrail.from_config({})
    assert default.enabled and default.mask_email and default.mask_card and not default.restore_in_reply
    assert not Guardrail.from_config({"guardrails": {"enabled": False}}).enabled


# -------------------------------------------------------- ASR result forms

def test_plain_text_result():
    assert g().mask_asr_result("mail a@b.com") == "mail [EMAIL_1]"


def test_dict_result_masks_content_only():
    raw = {"content": "call 0912345678", "language": "en", "emotion": "happy"}
    out = g().mask_asr_result(raw)
    assert out == {"content": "call [PHONE_1]", "language": "en", "emotion": "happy"}
    assert raw["content"] == "call 0912345678"  # input not mutated


def test_json_string_result_masks_content_only():
    raw = json.dumps({"speaker": "Linh 0912345678", "content": "mail a@b.com"})
    out = json.loads(g().mask_asr_result(raw))
    assert out == {"speaker": "Linh 0912345678", "content": "mail [EMAIL_1]"}


def test_result_without_text_is_returned_unchanged():
    gr = g()
    assert gr.mask_asr_result("") == ""
    assert gr.mask_asr_result(None) is None
    assert gr.mask_asr_result({"language": "en"}) == {"language": "en"}
    assert gr.mask_asr_result("{not json 0912345678}") == "{not json [PHONE_1]}"


# ---------------------------------------------------------------- restore

def test_restore_is_off_by_default():
    gr = g()
    masked = gr.mask("call 0912345678")
    assert gr.restore(f"I will {masked}") == f"I will {masked}"


def test_restore_puts_real_values_back():
    gr = g(restore_in_reply=True, names=["Linh"])
    gr.mask("Linh: 0912 345 678, a@b.com")
    assert gr.restore("Hi [NAME_1], calling [PHONE_1] and [EMAIL_1]") == "Hi Linh, calling 0912 345 678 and a@b.com"


def test_restore_leaves_unknown_placeholders():
    gr = g(restore_in_reply=True)
    gr.mask("a@b.com")
    assert gr.restore("[EMAIL_1] [EMAIL_9] [PHONE_1]") == "a@b.com [EMAIL_9] [PHONE_1]"
