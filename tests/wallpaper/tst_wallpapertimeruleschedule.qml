import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperTimeRuleModel.js" as RuleModel
import "../../services/wallpaper/WallpaperTimeRuleSchedule.js" as Schedule

TestCase {
    name: "WallpaperTimeRuleSchedule"

    function rules(values) {
        return RuleModel.normalizeDocument({ rules: values }).rules
    }

    function partsForLocalMinute(localMinute, offset) {
        return {
            day: 1 + Math.floor(localMinute / 1440),
            minute: ((localMinute % 1440) + 1440) % 1440,
            timezoneOffset: offset || 0
        }
    }

    function linearParts(timestamp) {
        return partsForLocalMinute(Math.floor(timestamp / 60000), 0)
    }

    function test_findsOrdinaryStartAndEnd() {
        const values = rules([{ id: "work", playlistId: "focus",
            startMinute: 60, endMinute: 120 }])
        const before = Schedule.nextBoundary(values, "DP-1",
            30 * 60000, linearParts)
        compare(before.state, "scheduled")
        compare(before.nextAtMs, 60 * 60000)
        compare(before.current.state, "unmatched")
        compare(before.next.playlistId, "focus")

        const during = Schedule.nextBoundary(values, "DP-1",
            70 * 60000, linearParts)
        compare(during.nextAtMs, 120 * 60000)
        compare(during.next.state, "unmatched")
    }

    function test_springGapChangesAtOffsetBoundary() {
        const gapParts = function(timestamp) {
            const epochMinute = Math.floor(timestamp / 60000)
            const localMinute = epochMinute < 120
                ? epochMinute : epochMinute + 60
            return partsForLocalMinute(localMinute,
                epochMinute < 120 ? 0 : -60)
        }
        const values = rules([{ id: "gap", playlistId: "after-gap",
            startMinute: 150, endMinute: 300 }])
        const result = Schedule.nextBoundary(values, "DP-1",
            119 * 60000, gapParts)
        compare(result.nextAtMs, 120 * 60000)
        compare(result.local.minute, 180)
        compare(result.next.playlistId, "after-gap")
        compare(result.reason, "timezone-transition")

        const later = Schedule.nextBoundary(values, "DP-1",
            121 * 60000, gapParts)
        compare(later.nextAtMs, 240 * 60000)
        compare(later.next.state, "unmatched")
        compare(later.reason, "rule-boundary")
    }

    function test_fallRepeatCanExitAndReenterRule() {
        const repeatParts = function(timestamp) {
            const epochMinute = Math.floor(timestamp / 60000)
            const localMinute = epochMinute < 120
                ? epochMinute : epochMinute - 60
            return partsForLocalMinute(localMinute,
                epochMinute < 120 ? 0 : 60)
        }
        const values = rules([{ id: "repeat", playlistId: "morning",
            startMinute: 90, endMinute: 180 }])
        const exit = Schedule.nextBoundary(values, "DP-1",
            119 * 60000, repeatParts)
        compare(exit.nextAtMs, 120 * 60000)
        compare(exit.next.state, "unmatched")
        compare(exit.reason, "timezone-transition")

        const reenter = Schedule.nextBoundary(values, "DP-1",
            120 * 60000, repeatParts)
        compare(reenter.nextAtMs, 150 * 60000)
        compare(reenter.next.playlistId, "morning")
    }

    function test_weekdayFullDayChangesAtMidnight() {
        const values = rules([{ id: "tuesday", playlistId: "weekly",
            days: [2], startMinute: 0, endMinute: 0 }])
        const result = Schedule.nextBoundary(values, "DP-1",
            1430 * 60000, linearParts)
        compare(result.nextAtMs, 1440 * 60000)
        compare(result.local.day, 2)
        compare(result.next.playlistId, "weekly")
    }

    function test_overlapReportsWinningRuleChange() {
        const values = rules([
            { id: "base", playlistId: "base", startMinute: 0,
                endMinute: 0, priority: 0 },
            { id: "peak", playlistId: "peak", startMinute: 50,
                endMinute: 100, priority: 10 }
        ])
        const result = Schedule.nextBoundary(values, "DP-1",
            60 * 60000, linearParts)
        compare(result.current.playlistId, "peak")
        compare(result.nextAtMs, 100 * 60000)
        compare(result.next.playlistId, "base")
    }

    function test_noEnabledRuleDoesNoScan() {
        const values = rules([{ id: "off", playlistId: "none",
            enabled: false }])
        const result = Schedule.nextBoundary(values, "DP-1",
            0, linearParts)
        compare(result.state, "none")
        compare(result.minutesScanned, 0)
    }

    function test_unchangingEverydayRuleIsBounded() {
        const values = rules([{ id: "always", playlistId: "steady",
            startMinute: 0, endMinute: 0 }])
        const result = Schedule.nextBoundary(values, "DP-1",
            0, linearParts)
        compare(result.state, "none")
        compare(result.minutesScanned, Schedule.maximumScannedMinutes)
        compare(result.current.playlistId, "steady")
    }
}
