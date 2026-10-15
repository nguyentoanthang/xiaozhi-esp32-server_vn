from datetime import datetime
import cnlunar
from plugins_func.register import register_function, ToolType, ActionResponse, Action

get_lunar_function_desc = {
    "type": "function",
    "function": {
        "name": "get_lunar",
        "description": (
            "Used for lunar calendar and almanac (huangli) information for a specific date."
            "The user can specify what to query, such as: lunar date, Heavenly Stems and Earthly Branches, solar terms, Chinese zodiac, star sign, Eight Characters (bazi), auspicious/inauspicious activities, etc."
            "If no query content is specified, the Ganzhi year and lunar date are queried by default."
            "For basic queries such as 'what is today's lunar date' or 'today's lunar calendar date', use the information in the context directly and do not call this tool."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "date": {
                    "type": "string",
                    "description": "The date to query, in YYYY-MM-DD format, e.g. 2024-01-01. If not provided, the current date is used",
                },
                "query": {
                    "type": "string",
                    "description": "The content to query, e.g. lunar date, Heavenly Stems and Earthly Branches, festivals, solar terms, Chinese zodiac, star sign, Eight Characters (bazi), auspicious/inauspicious activities, etc.",
                },
            },
            "required": [],
        },
    },
}


@register_function("get_lunar", get_lunar_function_desc, ToolType.WAIT)
def get_lunar(date=None, query=None):
    """
    Get the current lunar calendar date, plus almanac information such as Heavenly Stems and Earthly Branches, solar terms, Chinese zodiac, star sign, Eight Characters (bazi), and auspicious/inauspicious activities
    """
    from core.utils.cache.manager import cache_manager, CacheType

    # If a date parameter is provided, use the specified date; otherwise use the current date
    if date:
        try:
            now = datetime.strptime(date, "%Y-%m-%d")
        except ValueError:
            return ActionResponse(
                Action.REQLLM,
                f"Invalid date format, please use YYYY-MM-DD format, e.g. 2024-01-01",
                None,
            )
    else:
        now = datetime.now()

    current_date = now.strftime("%Y-%m-%d")

    # If query is None, use the default text
    if query is None:
        query = "Default query: Ganzhi year and lunar date"

    # Try to get the lunar information from the cache
    lunar_cache_key = f"lunar_info_{current_date}"
    cached_lunar_info = cache_manager.get(CacheType.LUNAR, lunar_cache_key)
    if cached_lunar_info:
        return ActionResponse(Action.REQLLM, cached_lunar_info, None)

    response_text = f"Respond to the user's query request based on the following information, and provide information related to {query}:\n"

    lunar = cnlunar.Lunar(now, godType="8char")
    response_text += (
        "Lunar calendar information:\n"
        "%s year %s%s\n" % (lunar.lunarYearCn, lunar.lunarMonthCn[:-1], lunar.lunarDayCn)
        + "Ganzhi: %s year %s month %s day\n" % (lunar.year8Char, lunar.month8Char, lunar.day8Char)
        + "Zodiac: %s\n" % (lunar.chineseYearZodiac)
        + "Eight Characters (bazi): %s\n"
        % (
            " ".join(
                [lunar.year8Char, lunar.month8Char, lunar.day8Char, lunar.twohour8Char]
            )
        )
        + "Today's festivals: %s\n"
        % (
            ",".join(
                filter(
                    None,
                    (
                        lunar.get_legalHolidays(),
                        lunar.get_otherHolidays(),
                        lunar.get_otherLunarHolidays(),
                    ),
                )
            )
        )
        + "Today's solar term: %s\n" % (lunar.todaySolarTerms)
        + "Next solar term: %s %s-%s-%s (year-month-day)\n"
        % (
            lunar.nextSolarTerm,
            lunar.nextSolarTermYear,
            lunar.nextSolarTermDate[0],
            lunar.nextSolarTermDate[1],
        )
        + "This year's solar terms: %s\n"
        % (
            ", ".join(
                [
                    f"{term}(month {date[0]}, day {date[1]})"
                    for term, date in lunar.thisYearSolarTermsDic.items()
                ]
            )
        )
        + "Zodiac clash: %s\n" % (lunar.chineseZodiacClash)
        + "Star sign: %s\n" % (lunar.starZodiac)
        + "Nayin: %s\n" % lunar.get_nayin()
        + "Pengzu taboos: %s\n" % (lunar.get_pengTaboo(delimit=", "))
        + "Day officer: %s\n" % lunar.get_today12DayOfficer()[0]
        + "Day deity: %s(%s)\n"
        % (lunar.get_today12DayOfficer()[1], lunar.get_today12DayOfficer()[2])
        + "28 Mansions: %s\n" % lunar.get_the28Stars()
        + "Lucky deity directions: %s\n" % " ".join(lunar.get_luckyGodsDirection())
        + "Fetal deity today: %s\n" % lunar.get_fetalGod()
        + "Auspicious: %s\n" % ", ".join(lunar.goodThing[:10])
        + "Inauspicious: %s\n" % ", ".join(lunar.badThing[:10])
        + "(By default return the Ganzhi year and lunar date; only return today's auspicious/inauspicious activities when asked)"
    )

    # Cache the lunar information
    cache_manager.set(CacheType.LUNAR, lunar_cache_key, response_text)

    return ActionResponse(Action.REQLLM, response_text, None)
