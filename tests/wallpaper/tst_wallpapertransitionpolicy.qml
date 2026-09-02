import QtQuick
import QtTest
import "../../panels/wallpaper/WallpaperTransitionPolicy.js" as Policy

TestCase {
    name: "WallpaperTransitionPolicy"

    readonly property var ordinary: ({
        outgoingPath: "/wall/a.png",
        incomingPath: "/wall/b.mp4",
        outgoingBackend: "static",
        incomingBackend: "video"
    })

    function decide(overrides) {
        return Policy.decision(Object.assign({}, ordinary, overrides || ({})))
    }

    function test_defaultCrossfadeIsBoundedToTwoSlots() {
        const result = decide()
        verify(result.enabled)
        compare(result.durationMs, Policy.defaultDurationMs)
        compare(result.outgoingRetentionMs, result.durationMs)
        compare(result.maximumRendererSlots, 2)
        compare(result.reason, "crossfade")
    }

    function test_durationBounds() {
        compare(decide({ durationMs: 1 }).durationMs,
            Policy.minimumDurationMs)
        compare(decide({ durationMs: 9999 }).durationMs,
            Policy.maximumDurationMs)
        compare(decide({ durationMs: "invalid" }).durationMs,
            Policy.defaultDurationMs)
    }

    function test_initialInvalidAndSameRendererSkip() {
        compare(decide({ outgoingPath: "" }).reason, "initial-load")
        compare(decide({ incomingBackend: "" }).reason, "invalid-incoming")
        compare(decide({ incomingPath: "/wall/a.png",
            incomingBackend: "static" }).reason, "same-renderer")
    }

    function test_reducedMotionFailureAndRapidSelectionSkip() {
        compare(decide({ enabled: false }).reason, "disabled")
        compare(decide({ reducedMotion: true }).reason, "reduced-motion")
        compare(decide({ incomingFailed: true }).reason, "incoming-failed")
        compare(decide({ rapidSelection: true }).reason, "rapid-selection")
    }

    function test_failureTakesPrecedenceOverRapidReplacement() {
        const result = decide({
            incomingFailed: true,
            rapidSelection: true,
            resourcePressure: "high"
        })
        verify(!result.enabled)
        compare(result.reason, "incoming-failed")
        compare(result.maximumRendererSlots, 2)
    }

    function test_hiddenSuspendedAndEvictedPresentationSkips() {
        compare(decide({ presentationVisible: false }).reason,
            "not-visible")
        compare(decide({ outgoingSuspended: true }).reason,
            "playback-suspended")
        compare(decide({ outgoingEvicted: true }).reason,
            "decoder-evicted")
        compare(decide({ incomingSuspended: true }).reason,
            "playback-suspended")
        compare(decide({ incomingEvicted: true }).reason,
            "decoder-evicted")
    }

    function test_coveredStaticPairKeepsCheapCrossfade() {
        const result = decide({
            outgoingBackend: "static",
            incomingBackend: "static",
            presentationVisible: false
        })
        verify(result.enabled)
        compare(result.reason, "crossfade")
    }

    function test_pressureShortensOrSkips() {
        const moderate = decide({ durationMs: 600,
            resourcePressure: "moderate" })
        verify(moderate.enabled)
        compare(moderate.durationMs, Policy.pressuredDurationMs)
        compare(moderate.reason, "resource-pressure-shortened")
        const high = decide({ resourcePressure: "high" })
        verify(!high.enabled)
        compare(high.durationMs, 0)
        compare(high.reason, "resource-pressure")
    }

    function test_unknownPressureDoesNotInventARestriction() {
        const result = decide({ resourcePressure: "future-value" })
        verify(result.enabled)
        compare(result.durationMs, Policy.defaultDurationMs)
    }

    function test_everyRendererDirectionUsesOneSharedPolicy() {
        const backends = ["static", "animated-image", "video"]
        for (let outgoingIndex = 0; outgoingIndex < backends.length;
                ++outgoingIndex) {
            for (let incomingIndex = 0; incomingIndex < backends.length;
                    ++incomingIndex) {
                const outgoing = backends[outgoingIndex]
                const incoming = backends[incomingIndex]
                const result = decide({
                    outgoingPath: "/wall/outgoing-" + outgoingIndex,
                    incomingPath: "/wall/incoming-" + incomingIndex,
                    outgoingBackend: outgoing,
                    incomingBackend: incoming
                })
                verify(result.enabled, outgoing + " -> " + incoming)
                compare(result.reason, "crossfade")
                compare(result.maximumRendererSlots, 2)
                compare(result.outgoingRetentionMs, result.durationMs)
            }
        }
    }
}
