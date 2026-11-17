import QtQuick
import QtTest
import "../../services/weather/WeatherConditions.js" as Weather

TestCase {
    name: "WeatherConditions"

    function test_currentWeatherRejectsIncompletePayload() {
        compare(Weather.currentFromJson({}), null);
        compare(Weather.currentFromJson({
            current: {
                temperature_2m: 12
            }
        }), null);
        compare(Weather.currentFromJson({
            current: {
                temperature_2m: "bad",
                weather_code: 3
            }
        }), null);
    }

    function test_currentWeatherPreservesMeaningfulFacts() {
        const current = Weather.currentFromJson({
            current: {
                temperature_2m: 17.6,
                weather_code: 61,
                is_day: 0
            }
        });
        compare(current.temperatureC, 17.6);
        compare(current.code, 61);
        compare(current.isDay, false);
        compare(Weather.kind(current.code), "rain");
        compare(Weather.description(current.code), "Rain");
    }

    function test_dayAndNightClearWeatherHaveDistinctGlyphs() {
        verify(Weather.glyph(0, true) !== Weather.glyph(0, false));
        compare(Weather.kind(95), "storm");
        compare(Weather.glyph(-1, true), "");
    }
}
