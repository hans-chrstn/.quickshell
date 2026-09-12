import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperTimeRuleModel.js" as Rules

TestCase {
    name: "WallpaperTimeRuleModel"

    function normalized(values) {
        return Rules.normalizeDocument({ rules: values }).rules
    }

    function test_normalWindowUsesInclusiveStartExclusiveEnd() {
        const rules = normalized([{ id: "day", playlistId: "light",
            days: [1], startMinute: 480, endMinute: 1020 }])
        compare(Rules.resolve(rules, "DP-1", 1, 480).playlistId, "light")
        compare(Rules.resolve(rules, "DP-1", 1, 1019).playlistId, "light")
        compare(Rules.resolve(rules, "DP-1", 1, 1020).state, "unmatched")
        compare(Rules.resolve(rules, "DP-1", 2, 480).state, "unmatched")
    }

    function test_overnightWindowUsesPreviousSelectedDay() {
        const rules = normalized([{ id: "night", playlistId: "dark",
            days: [5], startMinute: 1320, endMinute: 360 }])
        compare(Rules.resolve(rules, "DP-1", 5, 1380).playlistId, "dark")
        compare(Rules.resolve(rules, "DP-1", 6, 300).playlistId, "dark")
        compare(Rules.resolve(rules, "DP-1", 6, 360).state, "unmatched")
        compare(Rules.resolve(rules, "DP-1", 5, 300).state, "unmatched")
    }

    function test_equalBoundaryMeansSelectedFullDay() {
        const rules = normalized([{ id: "all-day", playlistId: "ambient",
            days: [0], startMinute: 0, endMinute: 0 }])
        compare(Rules.resolve(rules, "DP-1", 0, 0).playlistId, "ambient")
        compare(Rules.resolve(rules, "DP-1", 0, 1439).playlistId, "ambient")
        compare(Rules.resolve(rules, "DP-1", 1, 0).state, "unmatched")
    }

    function test_overlapOrderIsPriorityScopeThenStableId() {
        const rules = normalized([
            { id: "z-global", playlistId: "global", priority: 5 },
            { id: "z-screen", playlistId: "screen-z", screenName: "DP-1",
                priority: 5 },
            { id: "a-screen", playlistId: "screen-a", screenName: "DP-1",
                priority: 5 },
            { id: "higher", playlistId: "high", priority: 6 }
        ])
        compare(Rules.resolve(rules, "DP-1", 2, 500).playlistId, "high")
        rules[3].enabled = false
        const scoped = Rules.resolve(rules, "DP-1", 2, 500)
        compare(scoped.playlistId, "screen-a")
        compare(scoped.candidateCount, 3)
        compare(Rules.resolve(rules, "DP-2", 2, 500).playlistId, "global")
    }

    function test_normalizationIsBoundedAndDefensive() {
        const source = [{ id: "same", playlistId: "a", days: [6, -1, 6, 2],
            startMinute: -50, endMinute: 9999, priority: 9999 },
        { id: "same", playlistId: "b", priority: -9999 },
        { id: "missing-playlist" }]
        const rules = normalized(source)
        compare(rules.length, 2)
        compare(rules[0].id, "same")
        compare(rules[1].id, "same-2")
        compare(JSON.stringify(rules[0].days), JSON.stringify([2, 6]))
        compare(rules[0].startMinute, 0)
        compare(rules[0].endMinute, 1439)
        compare(rules[0].priority, 1000)
        compare(rules[1].priority, -1000)
        source[0].days.push(3)
        compare(JSON.stringify(rules[0].days), JSON.stringify([2, 6]))
    }

    function test_disabledAndWrongScreenDoNotMatch() {
        const rules = normalized([
            { id: "off", playlistId: "a", enabled: false },
            { id: "other", playlistId: "b", screenName: "DP-3" }
        ])
        compare(Rules.resolve(rules, "DP-1", 1, 500).state, "unmatched")
    }

    function test_ruleCountStopsAtDocumentLimit() {
        const source = []
        for (let index = 0; index < Rules.maximumRules + 12; ++index)
            source.push({ id: "rule-" + index, playlistId: "playlist" })
        const rules = normalized(source)
        compare(rules.length, Rules.maximumRules)
        compare(rules[0].id, "rule-0")
        compare(rules[rules.length - 1].id,
            "rule-" + (Rules.maximumRules - 1))
    }
}
