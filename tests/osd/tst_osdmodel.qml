import QtQuick
import QtTest
import "../../services/osd/OsdModel.js" as Model

TestCase {
    name: "OsdModel"

    function test_normalizesVisibleStates() {
        const volume = Model.normalized("volume", 0.54, false, "DP-1");
        compare(volume.title, "Volume");
        compare(volume.valueText, "54%");
        compare(volume.glyph, "volumeHigh");
        compare(Model.normalized("volume", 0.54, true, "DP-1").valueText, "Muted");
        compare(Model.normalized("microphone", 1, true, "DP-1").glyph, "microphoneMuted");
        compare(Model.normalized("brightness", 2, false, "DP-1").level, 1);
    }

    function test_rejectsInvalidEventsAndIgnoresLeds() {
        compare(Model.normalized("unknown", 0.5, false, "DP-1"), null);
        compare(Model.normalized("volume", NaN, false, "DP-1"), null);
        compare(Model.backlightFromBrightnessctl("input1::numlock,leds,0,0%,1"), null);
        const backlight = Model.backlightFromBrightnessctl("intel_backlight,backlight,180,50%,360");
        compare(backlight.name, "intel_backlight");
        compare(backlight.level, 0.5);
    }
}
