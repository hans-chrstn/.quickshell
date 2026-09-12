import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperScheduleDiagnostics.js" as Diagnostics

TestCase {
    name: "WallpaperScheduleDiagnostics"

    function test_derivesDynamicOutputStatesWithoutFixedMonitorNames() {
        const result = Diagnostics.derive(["internal", "dock", "projector"], {
            internal: { playlistId: "day", entryId: "a", path: "/a.png",
                nextAtMs: 2000, selectionSource: "target", timeRuleId: "" }
        }, {
            dock: { nextAtMs: 3000, effectiveSource: "target",
                effectivePlaylistId: "night", activeRuleId: "" }
        }, { global: false, screens: { projector: true } })
        compare(result.connectedCount, 3)
        compare(result.eligibleCount, 2)
        compare(result.plannedCount, 1)
        compare(result.waitingCount, 1)
        compare(result.suppressedCount, 1)
        compare(result.outputs.internal.state, "scheduled")
        compare(result.outputs.dock.state, "waiting-for-rule")
        compare(result.outputs.projector.state, "manual-suppressed")
    }

    function test_globalOverrideSuppressesEveryConnectedOutput() {
        const result = Diagnostics.derive(["one", "two"], {
            one: { playlistId: "playlist", path: "/one.png" }
        }, {}, { global: true, screens: {} })
        compare(result.eligibleCount, 0)
        compare(result.suppressedCount, 2)
        compare(result.plannedCount, 0)
        compare(result.outputs.one.path, "/one.png")
        verify(result.outputs.one.manualSuppressed)
        verify(result.outputs.two.manualSuppressed)
    }

    function test_namesAreDeduplicatedAndEmptyStateDoesNoWork() {
        const empty = Diagnostics.derive([], {}, {}, {})
        compare(empty.connectedCount, 0)
        compare(Object.keys(empty.outputs).length, 0)
        const result = Diagnostics.derive(["DP-1", "", "DP-1"], {}, {}, {})
        compare(result.connectedCount, 1)
        compare(result.outputs["DP-1"].state, "idle")
    }
}
