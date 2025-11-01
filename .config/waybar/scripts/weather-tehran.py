#!/usr/bin/env python3

import json
import sys
import urllib.error
import urllib.request

WTTR_URL = "https://wttr.in/Tehran?format=j1"


def fetch_weather():
    request = urllib.request.Request(
        WTTR_URL,
        headers={"User-Agent": "curl/7.88.1"},
    )
    with urllib.request.urlopen(request, timeout=5) as response:
        if response.status != 200:
            raise RuntimeError(f"Unexpected status code: {response.status}")
        return json.load(response)


def pick_icon(description: str) -> str:
    desc = (description or "").lower()
    mapping = [
        ("thunder", "⛈️"),
        ("storm", "⛈️"),
        ("snow", "❄️"),
        ("sleet", "🌨️"),
        ("blizzard", "🌨️"),
        ("rain", "🌧️"),
        ("shower", "🌦️"),
        ("drizzle", "🌦️"),
        ("cloudy", "☁️"),
        ("overcast", "☁️"),
        ("mist", "🌫️"),
        ("fog", "🌫️"),
        ("sunny", "☀️"),
        ("clear", "☀️"),
        ("partly", "⛅"),
    ]
    for key, icon in mapping:
        if key in desc:
            return icon
    return "🌡️"


def build_payload(data):
    current = (data.get("current_condition") or [{}])[0]
    temp = current.get("temp_C") or "--"
    feels_like = current.get("FeelsLikeC") or "--"
    humidity = current.get("humidity") or "--"
    wind = current.get("windspeedKmph") or "--"
    pressure = current.get("pressure") or "--"
    description = ""
    weather_desc = current.get("weatherDesc") or []
    if weather_desc:
        description = weather_desc[0].get("value", "")

    icon = pick_icon(description)
    text = f"{icon} {temp}°C"

    tooltip_lines = [
        description or "Weather unavailable",
        f"Feels like: {feels_like}°C",
        f"Wind: {wind} km/h",
        f"Humidity: {humidity}%",
        f"Pressure: {pressure} hPa",
    ]
    tooltip = "\n".join(tooltip_lines)

    return {"text": text, "tooltip": tooltip}


def main():
    try:
        data = fetch_weather()
        payload = build_payload(data)
    except (urllib.error.URLError, urllib.error.HTTPError, RuntimeError, json.JSONDecodeError):
        payload = {
            "text": "🌡️ --°C",
            "tooltip": "Weather unavailable",
        }
    json.dump(payload, sys.stdout)


if __name__ == "__main__":
    main()
