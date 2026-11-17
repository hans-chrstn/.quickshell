pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.services
import "NotificationModel.js" as NotificationModel
import "NotificationHistory.js" as NotificationHistory

Singleton {
    id: root

    property var queue: []
    property var history: []
    property bool doNotDisturb: false
    property bool historyLoaded: false
    property bool historyClearedBeforeLoad: false
    property bool dndChangedBeforeLoad: false
    property string historyError: ""
    property int sequence: 0
    property bool presentationVisible: false
    property var presentedScreens: ({})
    readonly property bool viewPresented: Object.keys(presentedScreens).length > 0
    property bool hovered: false
    property double expiresAtMs: 0
    property int remainingDurationMs: 0
    readonly property var current: queue.length > 0 ? queue[0] : null
    readonly property bool hasPresentation: current !== null
    readonly property var historyGroups: NotificationHistory.groups(history)
    signal closureRequested(string noticeId, string reason)

    function submit(request) {
        sequence += 1;
        const source = Object.assign({}, request || ({}));
        source.screenName = ScreenService.resolve(source.screenName || "");
        if (doNotDisturb) {
            const notice = NotificationModel.normalize(source, Date.now(), sequence);
            if (!notice)
                return "";
            history = NotificationHistory.insert(history, notice, Date.now());
            if (historyLoaded)
                saveTimer.restart();
            return notice.id;
        }
        const result = NotificationModel.enqueue(queue, source, Date.now(), sequence);
        if (!result.accepted)
            return "";
        const becomesCurrent = result.queue[0]?.id === result.notice.id;
        queue = result.queue;
        history = NotificationHistory.insert(history, result.notice, Date.now());
        if (historyLoaded)
            saveTimer.restart();
        if (!presentationVisible) {
            closeTimer.stop();
            presentationVisible = true;
        }
        if (becomesCurrent && viewPresented && !hovered)
            beginExpiry(true);
        return result.notice.id;
    }

    function notify(request) {
        return submit(request).length > 0;
    }

    function update(noticeId, request) {
        const index = queue.findIndex(item => item.id === noticeId);
        if (index < 0)
            return false;
        sequence += 1;
        const previous = queue[index];
        const source = Object.assign({}, request || ({}));
        source.screenName = previous.screenName;
        const updated = NotificationModel.normalize(source, Date.now(), sequence);
        if (!updated)
            return false;
        updated.id = previous.id;
        updated.createdAtMs = previous.createdAtMs;
        updated.occurrenceCount = previous.occurrenceCount;
        const next = queue.slice();
        next[index] = updated;
        queue = next;
        history = NotificationHistory.insert(history, updated, Date.now());
        if (historyLoaded)
            saveTimer.restart();
        if (index === 0 && presentationVisible && viewPresented && !hovered)
            beginExpiry(true);
        return true;
    }

    function showError(title, message, screenName, dedupeKey, source) {
        return notify({
            severity: "error",
            title: title,
            message: message,
            screenName: screenName,
            dedupeKey: dedupeKey,
            source: source
        });
    }

    function showWarning(title, message, screenName, dedupeKey, source) {
        return notify({
            severity: "warning",
            title: title,
            message: message,
            screenName: screenName,
            dedupeKey: dedupeKey,
            source: source
        });
    }

    function showSuccess(title, message, screenName, dedupeKey, source) {
        return notify({
            severity: "success",
            title: title,
            message: message,
            screenName: screenName,
            dedupeKey: dedupeKey,
            source: source
        });
    }

    function setPresented(screenName, value) {
        const key = String(screenName || "view");
        const next = Boolean(value);
        if (next === Boolean(presentedScreens[key]))
            return;
        const updated = Object.assign({}, presentedScreens);
        if (next)
            updated[key] = true;
        else
            delete updated[key];
        presentedScreens = updated;
        if (!viewPresented) {
            pauseExpiry();
            hovered = false;
            return;
        }
        if (current && presentationVisible && !hovered)
            beginExpiry(false);
    }

    function beginExpiry(resetDeadline) {
        if (!current || !presentationVisible || !viewPresented || hovered)
            return;
        const now = Date.now();
        if (resetDeadline || remainingDurationMs <= 0)
            remainingDurationMs = Math.max(NotificationModel.minimumDurationMs, Number(current.durationMs) || 4200);
        expiresAtMs = now + remainingDurationMs;
        const remaining = Math.round(expiresAtMs - now);
        if (remaining <= 0) {
            dismiss();
            return;
        }
        expiryTimer.interval = remaining;
        expiryTimer.restart();
    }

    function pauseExpiry() {
        if (expiryTimer.running && expiresAtMs > 0)
            remainingDurationMs = Math.max(1, Math.round(expiresAtMs - Date.now()));
        expiryTimer.stop();
        expiresAtMs = 0;
    }

    function dismiss(reason) {
        if (!current || !presentationVisible)
            return;
        const closingId = current.id;
        expiryTimer.stop();
        expiresAtMs = 0;
        remainingDurationMs = 0;
        presentationVisible = false;
        closeTimer.restart();
        closureRequested(closingId, reason === "expired" ? "expired" : "dismissed");
    }

    function remove(noticeId) {
        const index = queue.findIndex(item => item.id === noticeId);
        if (index < 0)
            return false;
        if (index === 0) {
            expiryTimer.stop();
            expiresAtMs = 0;
            remainingDurationMs = 0;
            presentationVisible = false;
            closeTimer.restart();
        } else {
            const next = queue.slice();
            next.splice(index, 1);
            queue = next;
        }
        return true;
    }

    function setHovered(value) {
        const next = Boolean(value);
        if (next === hovered)
            return;
        hovered = next;
        if (!current || !presentationVisible || !viewPresented)
            return;
        if (hovered)
            pauseExpiry();
        else
            beginExpiry(false);
    }

    function advance() {
        if (queue.length === 0)
            return;
        queue = queue.slice(1);
        if (current) {
            presentationVisible = true;
            expiresAtMs = 0;
            remainingDurationMs = 0;
            if (viewPresented && !hovered)
                beginExpiry(true);
        }
    }

    function clear() {
        for (const notice of queue)
            closureRequested(notice.id, "dismissed");
        expiryTimer.stop();
        closeTimer.stop();
        queue = [];
        presentationVisible = false;
        presentedScreens = ({});
        hovered = false;
        expiresAtMs = 0;
        remainingDurationMs = 0;
    }

    function clearHistory() {
        clear();
        history = [];
        if (!historyLoaded)
            historyClearedBeforeLoad = true;
        if (historyLoaded)
            saveTimer.restart();
    }

    function removeHistory(noticeId) {
        if (!history.some(item => item.id === noticeId))
            return false;
        history = NotificationHistory.remove(history, noticeId);
        if (historyLoaded)
            saveTimer.restart();
        return true;
    }

    function setDoNotDisturb(value) {
        const next = Boolean(value);
        if (next === doNotDisturb)
            return false;
        if (next)
            clear();
        if (!historyLoaded)
            dndChangedBeforeLoad = true;
        doNotDisturb = next;
        if (historyLoaded)
            saveTimer.restart();
        return true;
    }

    function historySnapshot(lockSafe) {
        return {
            doNotDisturb: doNotDisturb,
            count: history.length,
            error: historyError,
            entries: lockSafe ? NotificationHistory.lockSafe(history) : history.slice()
        };
    }

    function snapshot() {
        return {
            queueLength: queue.length,
            maximumQueueLength: NotificationModel.maximumQueueLength,
            visible: presentationVisible,
            viewPresented: viewPresented,
            hovered: hovered,
            expiresAtMs: expiresAtMs,
            remainingDurationMs: remainingDurationMs,
            current: current ? Object.assign({}, current) : null,
            historyCount: history.length,
            doNotDisturb: doNotDisturb
        };
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: {
            historyData.entries = root.history;
            historyData.doNotDisturb = root.doNotDisturb;
            historyFile.writeAdapter();
        }
    }

    FileView {
        id: historyFile
        path: Quickshell.statePath("notification-history.json")
        printErrors: false
        onLoaded: {
            try {
                const stored = JSON.parse(text());
                if (stored.schemaVersion !== 1 || !Array.isArray(stored.entries))
                    throw new Error("Unsupported notification history format");
                if (!root.historyClearedBeforeLoad)
                    root.history = NotificationHistory.merge(stored.entries, root.history, Date.now());
                if (!root.dndChangedBeforeLoad) {
                    if (stored.doNotDisturb === true)
                        root.clear();
                    root.doNotDisturb = stored.doNotDisturb === true;
                }
                root.historyError = "";
            } catch (exception) {
                root.historyError = "Notification history could not be loaded";
            }
            root.historyLoaded = true;
            if (root.history.length > 0 || root.dndChangedBeforeLoad || root.historyClearedBeforeLoad)
                saveTimer.restart();
        }
        onLoadFailed: failure => {
            root.historyLoaded = true;
            root.historyError = failure === FileViewError.FileNotFound ? "" : "Notification history could not be loaded";
            if (root.history.length > 0 || root.doNotDisturb || root.historyClearedBeforeLoad)
                saveTimer.restart();
        }

        JsonAdapter {
            id: historyData
            property int schemaVersion: 1
            property var entries: []
            property bool doNotDisturb: false
        }
    }

    Timer {
        id: expiryTimer
        onTriggered: root.dismiss("expired")
    }

    Timer {
        id: closeTimer
        interval: Design.moduleHandoffDuration
        onTriggered: root.advance()
    }
}
