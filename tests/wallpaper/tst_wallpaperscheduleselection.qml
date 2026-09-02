import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperScheduleSelection.js" as Selection

TestCase {
    name: "WallpaperScheduleSelection"

    function fixedParts(day, minute) {
        return function(timestamp) {
            const offset = Math.floor((timestamp - 60000) / 60000)
            return {
                day: (day + Math.floor((minute + offset) / 1440)) % 7,
                minute: (minute + offset) % 1440,
                timezoneOffset: 0,
                year: 2026,
                month: 1,
                date: 1 + Math.floor((minute + offset) / 1440)
            }
        }
    }

    function test_matchingRuleOverridesFallback() {
        const result = Selection.select([{ id: "day", enabled: true,
            playlistId: "rule", screenName: "", days: [1],
            startMinute: 480, endMinute: 600, priority: 1 }],
            "DP-1", "fallback", 60000, fixedParts(1, 500))
        compare(result.playlistId, "rule")
        compare(result.source, "time-rule")
        compare(result.ruleId, "day")
    }

    function test_unmatchedRuleUsesFallback() {
        const result = Selection.select([{ id: "day", enabled: true,
            playlistId: "rule", screenName: "", days: [1],
            startMinute: 480, endMinute: 600, priority: 1 }],
            "DP-1", "fallback", 60000, fixedParts(1, 700))
        compare(result.playlistId, "fallback")
        compare(result.source, "target")
        compare(result.ruleId, "")
    }

    function test_unrelatedScreenRuleDoesNoBoundaryScan() {
        const result = Selection.select([{ id: "other", enabled: true,
            playlistId: "rule", screenName: "DP-3", days: [],
            startMinute: 480, endMinute: 600, priority: 1 }],
            "DP-1", "fallback", 60000, fixedParts(1, 500))
        compare(result.playlistId, "fallback")
        compare(result.rulePlan.minutesScanned, 0)
        compare(result.rulePlan.nextAtMs, 0)
    }

    function test_scopedRuleStillIncludesGlobalCompetitor() {
        const result = Selection.select([
            { id: "global", enabled: true, playlistId: "global",
                screenName: "", days: [], startMinute: 0,
                endMinute: 0, priority: 5 },
            { id: "screen", enabled: true, playlistId: "screen",
                screenName: "DP-3", days: [], startMinute: 0,
                endMinute: 0, priority: 5 }
        ], "DP-3", "fallback", 60000, fixedParts(1, 500))
        compare(result.playlistId, "screen")
        compare(result.ruleId, "screen")
    }

    function test_cachedBoundaryAvoidsRepeatedScan() {
        const cached = {
            nextAtMs: 5000,
            observedTimezoneOffset: 240,
            minutesScanned: 500,
            current: { state: "unmatched", ruleId: "", playlistId: "" }
        }
        const result = Selection.reuse(cached, "DP-1", "fallback",
            3000, 2000, 240)
        verify(result !== null)
        compare(result.playlistId, "fallback")
        compare(result.rulePlan.minutesScanned, 0)
        compare(result.rulePlan.reason, "cached-boundary")
        compare(cached.minutesScanned, 500)
    }

    function test_cacheInvalidatesAtBoundaryRollbackAndTimezoneChange() {
        const cached = {
            nextAtMs: 5000,
            observedTimezoneOffset: 240,
            current: { state: "unmatched" }
        }
        compare(Selection.reuse(cached, "DP-1", "fallback",
            5000, 2000, 240), null)
        compare(Selection.reuse(cached, "DP-1", "fallback",
            1000, 2000, 240), null)
        compare(Selection.reuse(cached, "DP-1", "fallback",
            3000, 2000, 300), null)
    }
}
