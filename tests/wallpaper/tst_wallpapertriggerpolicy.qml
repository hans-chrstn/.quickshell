import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTriggerPolicy.js" as Policy

TestCase {
    name: "WallpaperTriggerPolicy"

    function test_orderIsStableAndDisabledLast() {
        const markers = [
            {
                id: "b",
                timeMs: 1000,
                enabled: true
            },
            {
                id: "a",
                timeMs: 1000,
                enabled: true
            },
            {
                id: "c",
                timeMs: 0,
                enabled: false
            }
        ];
        const result = Policy.ordered(markers);
        compare(result.map(marker => marker.id).join(","), "a,b,c");
        compare(markers[0].id, "b");
    }

    function test_eligibleHonorsEnabledAndCooldown() {
        verify(Policy.eligible({
            enabled: true
        }, 5000, 3000, 1000));
        verify(!Policy.eligible({
            enabled: true
        }, 3500, 3000, 1000));
        verify(!Policy.eligible({
            enabled: false
        }, 5000, 0, 0));
    }

    function test_eligibleRejectsInvalidClockValues() {
        verify(!Policy.eligible({
            enabled: true
        }, NaN, 0, 0));
        verify(!Policy.eligible({
            enabled: true
        }, 1000, Infinity, 0));
    }

    function test_missingHistoryAllowsFirstFire() {
        const marker = {
            id: "first-fire",
            enabled: true,
            cooldownMs: 60000,
            timeMs: 1000
        };
        verify(Policy.eligible(marker, 1000, undefined));
        const candidates = Policy.candidates([marker], 1000, {});
        compare(candidates.length, 1);
        compare(candidates[0].id, "first-fire");
        compare(Policy.eventDecision(marker, 1000, 1000, undefined).reason, "due");
    }

    function test_candidatesUsePriorityExclusivityAndMarkerCooldown() {
        const markers = [
            {
                id: "low",
                timeMs: 0,
                priority: 1,
                enabled: true,
                cooldownMs: 1000
            },
            {
                id: "high",
                timeMs: 500,
                priority: 5,
                enabled: true,
                cooldownMs: 2000
            },
            {
                id: "stale",
                timeMs: 1000,
                priority: 9,
                enabled: true,
                cooldownMs: 5000,
                exclusive: true
            }
        ];
        const result = Policy.candidates(markers, 3000, {
            stale: 0,
            high: 500,
            low: 2500
        });
        compare(result.length, 1);
        compare(result[0].id, "high");
    }

    function test_eventDecisionExplainsMissedAndDueEvents() {
        const marker = {
            enabled: true,
            cooldownMs: 0,
            missedEvent: "skip"
        };
        compare(Policy.eventDecision(marker, 1000, 1000, 0).reason, "due");
        compare(Policy.eventDecision(marker, 900, 1000, 0).reason, "missed");
        marker.missedEvent = "fire-on-resume";
        compare(Policy.eventDecision(marker, 900, 1000, 0).reason, "missed-replay");
    }

    function test_loopPolicyAllowsOnlyConfiguredRepeats() {
        verify(Policy.canLoop({
            enabled: true,
            loopPolicy: "once"
        }, 0));
        verify(!Policy.canLoop({
            enabled: true,
            loopPolicy: "once"
        }, 1));
        verify(Policy.canLoop({
            enabled: true,
            loopPolicy: "repeat"
        }, 8));
    }

    function test_decisionTraceIsStableAndExplainable() {
        const result = Policy.decisionTrace([
            {
                id: "late",
                timeMs: 5000,
                priority: 1,
                enabled: true
            },
            {
                id: "disabled",
                timeMs: 0,
                priority: 9,
                enabled: false
            }
        ], 1000, {});
        compare(result[0].id, "late");
        compare(result[0].reason, "not-due");
        compare(result[1].id, "disabled");
        compare(result[1].reason, "disabled");
    }

    function test_nextTimelineEventSkipsDisabledAndReportsWrap() {
        const markers = [
            {
                id: "disabled",
                timeMs: 100,
                enabled: false
            },
            {
                id: "first",
                timeMs: 200,
                enabled: true
            },
            {
                id: "last",
                timeMs: 800,
                enabled: true
            }
        ];
        compare(Policy.nextTimelineEvent(markers, 300, 1000, false).marker.id, "last");
        const wrapped = Policy.nextTimelineEvent(markers, 900, 1000, true);
        compare(wrapped.marker.id, "first");
        verify(wrapped.wrapped);
    }

    function test_nextTimelineEventUsesTimeBeforePriority() {
        const result = Policy.nextTimelineEvent([
            {
                id: "later-high-priority",
                timeMs: 5000,
                priority: 100,
                enabled: true
            },
            {
                id: "earlier-low-priority",
                timeMs: 2000,
                priority: -100,
                enabled: true
            }
        ], 1000, 6000, false);
        compare(result.marker.id, "earlier-low-priority");
    }
}
