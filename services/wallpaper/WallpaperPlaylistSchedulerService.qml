pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.session
import qs.services.wallpaper
import "WallpaperPlaylistSchedule.js" as Schedule

Singleton {
    id: root

    property bool loaded: false
    property string error: ""
    property alias cursors: data.cursors
    property var plans: ({})
    property bool refreshScheduled: false
    property string pendingReconcileReason: ""
    property double nextAtMs: 0
    property double timerWakeAtMs: 0
    property double lastReconcileAtMs: 0
    property string lastReconcileReason: ""
    property int lastAdvancedSteps: 0
    property int lastCyclesSkipped: 0
    property bool lockConsumerOwned: false
    readonly property bool active: Object.keys(plans).length > 0
    readonly property bool timerRunning: deadlineTimer.running
    readonly property bool lockStatePending: lockConsumerOwned
        && !SessionLockService.available
        && SessionLockService.error.length === 0
    readonly property bool applicationSuppressed:
        active && (lockStatePending || SessionLockService.locked
            || SessionLockService.preparingForSleep)
    readonly property string applicationSuppressedReason:
        SessionLockService.preparingForSleep ? "system-suspending"
        : SessionLockService.locked ? "session-locked"
        : lockStatePending ? "session-lock-pending" : ""
    readonly property int defaultEntryDurationMs: Schedule.defaultDurationMs
    readonly property int maximumCursors: 32
    readonly property int maximumTimerIntervalMs: 2147483647

    function initialize() {
        scheduleReconcile()
    }

    function normalizedScreen(value) {
        return String(value || "").trim().slice(0, 128)
    }

    function normalizedCursor(value) {
        return {
            playlistId: String(value?.playlistId || "").trim().slice(0, 96),
            entryId: String(value?.entryId || "").trim().slice(0, 96),
            startedAtMs: Math.max(0,
                Math.floor(Number(value?.startedAtMs) || 0))
        }
    }

    function connectedScreenNames() {
        const names = []
        for (const screen of Quickshell.screens) {
            const name = normalizedScreen(screen?.name)
            if (name.length > 0 && names.indexOf(name) < 0)
                names.push(name)
        }
        return names
    }

    function reconcile(nowMs, reason) {
        refreshScheduled = false
        pendingReconcileReason = ""
        if (!loaded || !WallpaperPlaylistService.loaded
                || !WallpaperPlaylistTargetService.loaded) {
            disarmTimer()
            return false
        }

        const now = Math.max(0, Math.floor(Number(nowMs) || Date.now()))
        const updatedCursors = ({})
        const updatedPlans = ({})
        let earliest = 0
        let greatestAdvance = 0
        let greatestCycleSkip = 0
        const connected = connectedScreenNames()

        for (const screenName of connected) {
            if (Object.keys(updatedCursors).length >= maximumCursors)
                break
            const playlistId = WallpaperPlaylistTargetService
                .playlistForScreen(screenName)
            if (playlistId.length === 0)
                continue
            const playlist = WallpaperPlaylistService
                .playlistSnapshot(playlistId)
            if (!playlist)
                continue
            const previous = normalizedCursor(cursors[screenName])
            const retained = previous.playlistId === playlistId
                ? previous : { playlistId: playlistId, entryId: "",
                    startedAtMs: 0 }
            const plan = Schedule.plan(
                WallpaperPlaylistService.resolvedEntries(playlistId),
                retained, now, defaultEntryDurationMs)
            if (plan.state !== "ready")
                continue
            greatestAdvance = Math.max(greatestAdvance,
                plan.advancedSteps)
            greatestCycleSkip = Math.max(greatestCycleSkip,
                plan.cyclesSkipped)
            updatedCursors[screenName] = {
                playlistId: playlistId,
                entryId: plan.entryId,
                startedAtMs: plan.startedAtMs
            }
            updatedPlans[screenName] = Object.assign({}, plan, {
                screenName: screenName,
                playlistId: playlistId,
                mode: playlist.mode
            })
            if (earliest <= 0 || plan.nextAtMs < earliest)
                earliest = plan.nextAtMs
        }

        for (const screenName in WallpaperPlaylistTargetService.screenPlaylistIds) {
            if (Object.keys(updatedCursors).length >= maximumCursors)
                break
            if (updatedCursors[screenName] !== undefined)
                continue
            const playlistId = WallpaperPlaylistTargetService
                .screenPlaylistIds[screenName]
            const previous = normalizedCursor(cursors[screenName])
            if (previous.playlistId === playlistId
                    && previous.entryId.length > 0)
                updatedCursors[screenName] = previous
        }

        cursors = updatedCursors
        plans = updatedPlans
        nextAtMs = earliest
        lastReconcileAtMs = now
        lastReconcileReason = String(reason || "state-change")
            .trim().slice(0, 64)
        lastAdvancedSteps = greatestAdvance
        lastCyclesSkipped = greatestCycleSkip
        error = ""
        armTimer(now)
        return true
    }

    function disarmTimer() {
        deadlineTimer.stop()
        timerWakeAtMs = 0
    }

    function armTimer(nowMs) {
        deadlineTimer.stop()
        timerWakeAtMs = 0
        if (!active || nextAtMs <= 0
                || SessionLockService.preparingForSleep)
            return
        const now = Math.max(0, Math.floor(Number(nowMs) || Date.now()))
        const remaining = Math.max(1, nextAtMs - now)
        const interval = Math.min(maximumTimerIntervalMs, remaining)
        deadlineTimer.interval = interval
        timerWakeAtMs = now + interval
        deadlineTimer.start()
    }

    function scheduleReconcile(reason) {
        const normalizedReason = String(reason || "state-change")
            .trim().slice(0, 64)
        if (pendingReconcileReason.length === 0)
            pendingReconcileReason = normalizedReason
        if (refreshScheduled)
            return
        refreshScheduled = true
        Qt.callLater(function() {
            root.reconcile(Date.now(), root.pendingReconcileReason)
        })
    }

    function updateLockConsumer() {
        if (active && !lockConsumerOwned) {
            lockConsumerOwned = true
            SessionLockService.acquire()
        } else if (!active && lockConsumerOwned) {
            lockConsumerOwned = false
            SessionLockService.release()
        }
    }

    function preview(screenName, nowMs, entryId, startedAtMs) {
        const screen = String(screenName || "").trim().slice(0, 128)
        const playlistId = WallpaperPlaylistTargetService
            .playlistForScreen(screen)
        if (playlistId.length === 0)
            return Object.assign(Schedule.dormant("no-playlist-target"), {
                screenName: screen,
                playlistId: ""
            })
        const playlist = WallpaperPlaylistService.playlistSnapshot(playlistId)
        if (!playlist)
            return Object.assign(Schedule.dormant("playlist-unavailable"), {
                screenName: screen,
                playlistId: playlistId
            })
        const entries = WallpaperPlaylistService.resolvedEntries(playlistId)
        return Object.assign(Schedule.plan(entries, {
            entryId: String(entryId || ""),
            startedAtMs: Number(startedAtMs) || 0
        }, Number(nowMs) || Date.now(), defaultEntryDurationMs), {
            screenName: screen,
            playlistId: playlistId,
            mode: playlist.mode
        })
    }

    function snapshot() {
        return {
            loaded: loaded,
            active: active,
            timerRunning: timerRunning,
            defaultEntryDurationMs: defaultEntryDurationMs,
            nextAtMs: nextAtMs,
            timerWakeAtMs: timerWakeAtMs,
            lastReconcileAtMs: lastReconcileAtMs,
            lastReconcileReason: lastReconcileReason,
            lastAdvancedSteps: lastAdvancedSteps,
            lastCyclesSkipped: lastCyclesSkipped,
            sessionLockAvailable: SessionLockService.available,
            sessionLocked: SessionLockService.locked,
            preparingForSleep: SessionLockService.preparingForSleep,
            applicationSuppressed: applicationSuppressed,
            applicationSuppressedReason: applicationSuppressedReason,
            cursors: Object.assign({}, cursors),
            plans: Object.assign({}, plans),
            error: error,
            state: active ? (applicationSuppressed
                ? "cursor-ready-suppressed" : "cursor-ready") : "dormant"
        }
    }

    onActiveChanged: updateLockConsumer()

    Connections {
        target: WallpaperPlaylistService
        function onLoadedChanged() { root.scheduleReconcile("playlist-loaded") }
        function onPlaylistsChanged() { root.scheduleReconcile("playlist-changed") }
    }

    Connections {
        target: WallpaperPlaylistTargetService
        function onLoadedChanged() { root.scheduleReconcile("targets-loaded") }
        function onGlobalPlaylistIdChanged() {
            root.scheduleReconcile("global-target-changed")
        }
        function onScreenPlaylistIdsChanged() {
            root.scheduleReconcile("screen-target-changed")
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() { root.scheduleReconcile("screens-changed") }
    }

    Connections {
        target: SessionLockService
        enabled: root.lockConsumerOwned
        function onLockedChanged() {
            root.scheduleReconcile(SessionLockService.locked
                ? "session-locked" : "session-unlocked")
        }
        function onPreparingForSleepChanged() {
            if (SessionLockService.preparingForSleep) {
                root.disarmTimer()
            } else {
                root.scheduleReconcile("system-resumed")
            }
        }
    }

    Timer {
        id: deadlineTimer
        repeat: false
        onTriggered: root.reconcile(Date.now(), "deadline")
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: stateFile.writeAdapter()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper-playlist-scheduler.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reload()
        onLoaded: {
            root.loaded = true
            if (!data.cursors || typeof data.cursors !== "object")
                root.cursors = ({})
            root.error = ""
            root.scheduleReconcile()
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.cursors = ({})
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper playlist scheduler state could not be loaded"
            root.scheduleReconcile()
        }

        JsonAdapter {
            id: data
            property int schemaVersion: 1
            property var cursors: ({})
        }
    }
}
