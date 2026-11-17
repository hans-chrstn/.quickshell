.pragma library

function kind(code) {
    const value = Number(code);
    if (!Number.isFinite(value) || value < 0)
        return "unknown";
    if (value <= 1)
        return "clear";
    if (value <= 3)
        return "cloud";
    if (value === 45 || value === 48)
        return "fog";
    if (value >= 51 && value <= 67 || value >= 80 && value <= 82)
        return "rain";
    if (value >= 71 && value <= 77 || value === 85 || value === 86)
        return "snow";
    if (value >= 95 && value <= 99)
        return "storm";
    return "unknown";
}

function glyph(code, isDay) {
    switch (kind(code)) {
    case "clear":
        return isDay ? "☀" : "☾";
    case "cloud":
        return "☁";
    case "fog":
        return "≋";
    case "rain":
        return "☂";
    case "snow":
        return "❄";
    case "storm":
        return "ϟ";
    default:
        return "";
    }
}

function description(code) {
    switch (kind(code)) {
    case "clear":
        return "Clear";
    case "cloud":
        return "Cloudy";
    case "fog":
        return "Fog";
    case "rain":
        return "Rain";
    case "snow":
        return "Snow";
    case "storm":
        return "Thunderstorm";
    default:
        return "Weather unavailable";
    }
}

function currentFromJson(source) {
    const current = source?.current;
    if (current?.temperature_2m === null || current?.weather_code === null || current?.temperature_2m === undefined || current?.weather_code === undefined)
        return null;
    const temperature = Number(current.temperature_2m);
    const code = Number(current.weather_code);
    if (!Number.isFinite(temperature) || !Number.isFinite(code))
        return null;
    return {
        temperatureC: temperature,
        code: code,
        isDay: Number(current?.is_day) === 1
    };
}
