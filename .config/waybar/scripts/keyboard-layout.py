#!/usr/bin/env python3

import json
import subprocess
import sys


def get_keyboard_layout():
    try:
        raw = subprocess.check_output(
            ["hyprctl", "-j", "devices"], stderr=subprocess.DEVNULL
        )
        data = json.loads(raw)
    except Exception:
        return None, None

    keyboards = data.get("keyboards") or []
    keyboard = next((kb for kb in keyboards if kb.get("main")), None)
    if keyboard is None and keyboards:
        keyboard = keyboards[0]

    if not keyboard:
        return None, None

    layout = keyboard.get("layout") or ""
    normalized = layout.split("(")[0].strip().lower()
    return layout, normalized


def layout_to_flag(normalized):
    flag_map = {
        "us": "🇺🇸",
        "en": "🇺🇸",
        "ir": "🇮🇷",
        "fa": "🇮🇷",
        "persian": "🇮🇷",
    }
    if not normalized:
        return "❓"
    return flag_map.get(normalized, normalized.upper())


def main():
    layout, normalized = get_keyboard_layout()
    flag = layout_to_flag(normalized)
    tooltip = layout or "Layout unavailable"
    payload = {"text": flag, "tooltip": tooltip}
    json.dump(payload, sys.stdout)


if __name__ == "__main__":
    main()
