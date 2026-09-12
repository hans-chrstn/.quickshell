import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperHookDiagnostics.js" as Diagnostics

TestCase {
    name: "WallpaperHookDiagnostics"

    function test_derivesDynamicProfileAndOutcomeCounts() {
        const result = Diagnostics.derive({ loaded: true, hooks: [
            { enabled: true, phase: "pre-change", screenName: "" },
            { enabled: true, phase: "post-change", screenName: "DP-1" },
            { enabled: false, phase: "pre-change", screenName: "" }
        ] }, { running: false, recentRuns: [
            { results: [{ outcome: "success" }, { outcome: "failed" }] },
            { results: [{ outcome: "timeout" }, { outcome: "cancelled" },
                { outcome: "start-failed" }] }
        ] }, {})

        compare(result.profiles.total, 3)
        compare(result.profiles.enabled, 2)
        compare(result.profiles.disabled, 1)
        compare(result.profiles.preChange, 1)
        compare(result.profiles.postChange, 1)
        compare(result.profiles.global, 1)
        compare(result.profiles.screenScoped, 1)
        compare(result.execution.retainedBatches, 2)
        compare(result.execution.retainedResults, 5)
        compare(result.execution.outcomes.success, 1)
        compare(result.execution.outcomes.failed, 1)
        compare(result.execution.outcomes.timeout, 1)
        compare(result.execution.outcomes.cancelled, 1)
        compare(result.execution.outcomes.startFailed, 1)
    }

    function test_emptyInputIsInert() {
        const result = Diagnostics.derive(null, null, null)
        verify(!result.loaded)
        compare(result.profiles.total, 0)
        verify(!result.execution.running)
        compare(result.execution.retainedResults, 0)
        compare(result.application.stage, "")
        verify(!result.application.reconcileQueued)
    }

    function test_preservesCurrentHandoffTruthfully() {
        const result = Diagnostics.derive({ hooks: [] }, {
            running: true,
            activeRunId: "run-1",
            activeHookId: "hook-1",
            pendingCount: 3,
            recentRuns: []
        }, {
            hookStage: "pre-change",
            hookRunId: "run-1",
            hookChangeCount: 2,
            reconcileQueued: true,
            staleBeforeApply: true
        })
        verify(result.execution.running)
        compare(result.execution.pendingCount, 3)
        compare(result.application.stage, "pre-change")
        compare(result.application.changeCount, 2)
        verify(result.application.reconcileQueued)
        verify(result.application.staleBeforeApply)
    }
}
