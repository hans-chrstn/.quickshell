pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperHookModel.js" as HookModel

Singleton {
    id: root

    property var pending: []
    property var activeJob: null
    property var activeResults: []
    property var lastRun: null
    property var recentRuns: []
    property string activeRunId: ""
    property string error: ""
    property int sequence: 0
    property bool timedOut: false
    property bool cancellationRequested: false
    property string cancellationReason: ""
    property bool processStarted: false
    property string forcedOutcome: ""

    readonly property int maximumBatchJobs: 256
    readonly property bool running: hookProcess.running || activeJob !== null
    readonly property int pendingCount: pending.length

    signal runFinished(string runId, var result)

    function runPhase(phase, context) {
        return runRequests([{ phase: phase, context: context }])
    }

    function runRequests(requests) {
        if (running || pending.length > 0) {
            error = "A wallpaper hook batch is already running"
            return ""
        }
        const jobs = []
        for (const request of (requests || [])) {
            const bounded = HookModel.boundedContext(request?.context)
            const hooks = HookModel.selected(WallpaperHookService.hooks,
                request?.phase, bounded.screen)
            for (const hook of hooks) {
                const invocation = HookModel.invocation(hook, bounded)
                if (invocation)
                    jobs.push(invocation)
                if (jobs.length > maximumBatchJobs) {
                    error = "Wallpaper hook batch limit exceeded"
                    return ""
                }
            }
        }
        if (jobs.length === 0) {
            error = ""
            return ""
        }
        sequence += 1
        activeRunId = "hook-run-" + Date.now().toString(36)
            + "-" + sequence.toString(36)
        activeResults = []
        pending = jobs
        cancellationRequested = false
        cancellationReason = ""
        error = ""
        startNext()
        return activeRunId
    }

    function startNext() {
        if (activeJob !== null || hookProcess.running)
            return
        if (pending.length === 0) {
            const result = {
                runId: activeRunId,
                finishedAtMs: Date.now(),
                cancelled: cancellationRequested,
                cancellationReason: cancellationReason,
                results: activeResults.slice()
            }
            lastRun = result
            recentRuns = recentRuns.concat([result]).slice(-16)
            const finishedId = activeRunId
            activeRunId = ""
            activeResults = []
            cancellationRequested = false
            cancellationReason = ""
            runFinished(finishedId, result)
            return
        }
        const remaining = pending.slice()
        activeJob = remaining.shift()
        pending = remaining
        timedOut = false
        processStarted = false
        forcedOutcome = ""
        hookProcess.command = activeJob.command
        hookProcess.running = true
        launchTimer.restart()
        timeoutTimer.interval = activeJob.timeoutMs
        timeoutTimer.restart()
    }

    function finishActive(exitCode, exitStatus) {
        if (activeJob === null)
            return
        timeoutTimer.stop()
        launchTimer.stop()
        killTimer.stop()
        const job = activeJob
        activeResults = activeResults.concat([{
            hookId: job.hookId,
            outcome: forcedOutcome.length > 0 ? forcedOutcome
                : timedOut ? "timeout"
                : cancellationRequested ? "cancelled"
                : (exitCode === 0 && exitStatus === 0 ? "success" : "failed"),
            exitCode: exitCode,
            crashed: exitStatus !== 0,
            timedOut: timedOut,
            cancelled: cancellationRequested
        }])
        activeJob = null
        timedOut = false
        processStarted = false
        forcedOutcome = ""
        Qt.callLater(startNext)
    }

    function failStart() {
        if (activeJob === null || processStarted)
            return
        forcedOutcome = "start-failed"
        hookProcess.running = false
        Qt.callLater(function() {
            if (root.activeJob !== null && !root.processStarted)
                root.finishActive(-1, 1)
        })
    }

    function cancelRun(runId, reason) {
        if (String(runId || "") !== activeRunId
                || activeRunId.length === 0)
            return false
        cancellationRequested = true
        cancellationReason = String(reason || "superseded")
            .trim().slice(0, 96)
        if (pending.length > 0) {
            activeResults = activeResults.concat(pending.map(job => ({
                hookId: job.hookId,
                outcome: "cancelled",
                exitCode: -1,
                crashed: false,
                timedOut: false,
                cancelled: true
            })))
            pending = []
        }
        timeoutTimer.stop()
        if (hookProcess.running) {
            hookProcess.signal(15)
            killTimer.restart()
        } else if (activeJob === null) {
            Qt.callLater(startNext)
        }
        return true
    }

    function snapshot() {
        return {
            running: running,
            activeRunId: activeRunId,
            activeHookId: activeJob?.hookId ?? "",
            pendingCount: pendingCount,
            maximumBatchJobs: maximumBatchJobs,
            cancellationRequested: cancellationRequested,
            cancellationReason: cancellationReason,
            lastRun: lastRun ? Object.assign({}, lastRun, {
                results: (lastRun.results || []).map(value =>
                    Object.assign({}, value))
            }) : null,
            recentRuns: recentRuns.map(run => Object.assign({}, run, {
                results: (run.results || []).map(value =>
                    Object.assign({}, value))
            })),
            error: error
        }
    }

    Process {
        id: hookProcess
        onStarted: {
            root.processStarted = true
            launchTimer.stop()
        }
        onExited: (exitCode, exitStatus) =>
            root.finishActive(exitCode, exitStatus)
    }

    Timer {
        id: launchTimer
        interval: 500
        onTriggered: root.failStart()
    }

    Timer {
        id: timeoutTimer
        onTriggered: {
            if (!hookProcess.running)
                return
            if (!root.processStarted) {
                root.failStart()
                return
            }
            root.timedOut = true
            hookProcess.signal(15)
            killTimer.restart()
        }
    }

    Timer {
        id: killTimer
        interval: 500
        onTriggered: if (hookProcess.running) hookProcess.signal(9)
    }
}
