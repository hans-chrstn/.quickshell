import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineMarker.js" as Marker

TestCase {
    name: "WallpaperTimelineMarker"

    function document() {
        return {
            project: {
                durationMs: 10000,
                markers: []
            }
        };
    }

    function test_addNormalizesAndPreservesInput() {
        const original = document();
        const result = Marker.add(original, "m1", "  Intro  ", 12000, "time", true);
        verify(result.accepted);
        compare(result.document.project.markers[0].name, "Intro");
        compare(result.document.project.markers[0].timeMs, 10000);
        compare(original.project.markers.length, 0);
    }

    function test_rejectsDuplicateAndUnknownType() {
        const first = Marker.add(document(), "m1", "Intro", 1000, "manual");
        verify(!Marker.add(first.document, "m1", "Again", 2000, "manual").accepted);
        verify(!Marker.add(document(), "m2", "Bad", 1000, "unknown").accepted);
    }

    function test_updateClampsAndToggles() {
        const first = Marker.add(document(), "m1", "Intro", 1000, "manual");
        const result = Marker.update(first.document, "m1", {
            timeMs: -20,
            enabled: false,
            triggerType: "weather"
        });
        verify(result.accepted);
        compare(result.document.project.markers[0].timeMs, 0);
        verify(!result.document.project.markers[0].enabled);
        compare(result.document.project.markers[0].triggerType, "weather");
    }

    function test_policyFieldsUseSafeDefaultsAndBounds() {
        const first = Marker.add(document(), "m1", "Intro", 1000, "manual");
        const result = Marker.update(first.document, "m1", {
            priority: 999,
            exclusive: true,
            cooldownMs: -1,
            debounceMs: 999999,
            missedEvent: "fire-on-resume",
            loopPolicy: "repeat",
            actions: [
                {
                    id: "fade",
                    type: "set-property",
                    target: "opacity",
                    value: 0.5
                }
            ]
        });
        verify(result.accepted);
        const marker = result.document.project.markers[0];
        compare(marker.priority, 100);
        verify(marker.exclusive);
        compare(marker.cooldownMs, 0);
        compare(marker.debounceMs, 60000);
        compare(marker.actions[0].type, "set-property");
        compare(marker.missedEvent, "fire-on-resume");
        compare(marker.loopPolicy, "repeat");
    }

    function test_removeIsImmutableAndRejectsMissing() {
        const first = Marker.add(document(), "m1", "Intro", 1000, "manual");
        const result = Marker.remove(first.document, "m1");
        verify(result.accepted);
        compare(result.document.project.markers.length, 0);
        compare(first.document.project.markers.length, 1);
        verify(!Marker.remove(result.document, "missing").accepted);
    }
}
