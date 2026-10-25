pragma Singleton

import QtQuick
import Quickshell
import "../../../core/JsonCopy.js" as JsonCopy
import "WallpaperTimelineEdit.js" as TimelineEdit
import "WallpaperTimelineDrop.js" as TimelineDrop
import "WallpaperTimelineBatchEdit.js" as BatchEdit
import "WallpaperTimelineGesture.js" as TimelineGesture
import "WallpaperTimelineGestureSession.js" as GestureSession
import "WallpaperTimelinePlacement.js" as Placement
import "WallpaperTimelineSelection.js" as TimelineSelection
import "WallpaperTimelineTrackEdit.js" as TrackEdit
import "WallpaperTimelineMarker.js" as MarkerEdit
import "WallpaperTriggerAction.js" as TriggerAction
import "WallpaperTriggerPolicy.js" as TriggerPolicy
import "WallpaperCommandHistory.js" as CommandHistory

Singleton {
    id: root

    property var session: GestureSession.idle("")
    property string error: ""
    property int gestureSequence: 0
    readonly property var selection: WallpaperEditorSelectionService.timelineSelection
    property var history: CommandHistory.empty(50)
    property string historyProjectId: ""
    readonly property bool gestureActive: session.active === true
    readonly property bool canUndo: history.past.length > 0
    readonly property bool canRedo: history.future.length > 0

    function activeDocument() {
        const id = WallpaperProjectService.activeProjectId;
        return id.length > 0 ? WallpaperProjectService.projectSnapshot(id) : null;
    }

    function recordHistory(before, after, label) {
        if (historyProjectId.length === 0)
            historyProjectId = WallpaperProjectService.activeProjectId;
        history = CommandHistory.push(history, {
            id: "timeline-command-" + Date.now().toString(36),
            label: String(label || "Timeline edit"),
            before: JsonCopy.value(before),
            after: JsonCopy.value(after)
        });
    }

    function applyHistoryDocument(document) {
        if (!document || !WallpaperProjectService.upsertJson(JSON.stringify(document)))
            return reject(WallpaperProjectService.error || "Timeline history could not be applied");
        error = "";
        return true;
    }

    function undo() {
        const result = CommandHistory.undo(history);
        if (!result.command)
            return false;
        if (!root.applyHistoryDocument(result.command.before))
            return false;
        history = result.state;
        WallpaperEditorSelectionService.reconcile(result.command.before);
        return true;
    }

    function redo() {
        const result = CommandHistory.redo(history);
        if (!result.command)
            return false;
        if (!root.applyHistoryDocument(result.command.after))
            return false;
        history = result.state;
        WallpaperEditorSelectionService.reconcile(result.command.after);
        return true;
    }

    function locateClip(document, clipId) {
        for (const track of document?.project?.tracks || []) {
            const clip = (track.clips || []).find(value => value.id === clipId);
            if (clip)
                return {
                    trackId: track.id,
                    clip: clip
                };
        }
        return null;
    }

    function nextGestureId() {
        gestureSequence += 1;
        return "timeline-gesture-" + Date.now().toString(36) + "-" + gestureSequence.toString(36);
    }

    function dropAsset(assetId, targetTrackId, startMs, sourceDurationMs) {
        if (gestureActive)
            return reject("Another timeline gesture is active");
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const operationId = nextGestureId();
        const planned = TimelineDrop.plan(document, {
            assetId: String(assetId || ""),
            trackId: String(targetTrackId || ""),
            startMs: startMs,
            sourceDurationMs: sourceDurationMs,
            clipId: operationId + "-clip",
            newTrackId: operationId + "-track"
        });
        if (!planned.accepted)
            return reject(planned.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(planned.document)))
            return reject(WallpaperProjectService.error || "Timeline drop could not be saved");
        root.recordHistory(document, planned.document, "Add media to timeline");
        error = "";
        return true;
    }

    function selectClip(trackId, clipId, mode) {
        const accepted = WallpaperEditorSelectionService.selectClip(trackId, clipId, mode);
        error = "";
        return accepted;
    }

    function selectAllClips() {
        const accepted = WallpaperEditorSelectionService.selectAllClips();
        error = "";
        return accepted;
    }

    function clearSelection() {
        WallpaperEditorSelectionService.clear();
    }

    function selectTrack(trackId) {
        const accepted = WallpaperEditorSelectionService.selectTrack(trackId);
        error = "";
        return accepted;
    }

    function removeSelectedClips() {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const command = TimelineSelection.command(selection, document.project.tracks, "remove", ({}));
        if (!command.accepted)
            return reject(command.error);
        const applied = BatchEdit.apply(document, command.command);
        if (!applied.accepted)
            return reject(applied.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(applied.document)))
            return reject(WallpaperProjectService.error || "Timeline clips could not be removed");
        root.recordHistory(document, applied.document, "Remove timeline media");
        clearSelection();
        error = "";
        return true;
    }

    function addTrack(type) {
        const trackType = String(type || "");
        if (trackType !== "media" && trackType !== "audio")
            return reject("Only Media and Audio tracks can be added here");
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const trackId = nextGestureId() + "-track";
        const added = TrackEdit.addTrack(document, trackId, trackType === "audio" ? "Audio" : "Media", trackType, document.project.tracks.length);
        if (!added.accepted)
            return reject(added.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(added.document)))
            return reject(WallpaperProjectService.error || "Timeline track could not be added");
        root.recordHistory(document, added.document, "Add " + trackType + " track");
        WallpaperEditorSelectionService.selectTrack(trackId);
        error = "";
        return true;
    }

    function addMarker(timeMs, triggerType) {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const markerId = nextGestureId() + "-marker";
        const added = MarkerEdit.add(document, markerId, "Marker", timeMs, triggerType || "manual", true);
        if (!added.accepted)
            return reject(added.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(added.document)))
            return reject(WallpaperProjectService.error || "Marker could not be added");
        root.recordHistory(document, added.document, "Add timeline marker");
        error = "";
        return true;
    }

    function removeMarker(markerId) {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const removed = MarkerEdit.remove(document, markerId);
        if (!removed.accepted)
            return reject(removed.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(removed.document)))
            return reject(WallpaperProjectService.error || "Marker could not be removed");
        root.recordHistory(document, removed.document, "Remove timeline marker");
        error = "";
        return true;
    }

    function moveMarker(markerId, timeMs) {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const updated = MarkerEdit.update(document, markerId, {
            timeMs: timeMs
        });
        if (!updated.accepted)
            return reject(updated.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(updated.document)))
            return reject(WallpaperProjectService.error || "Marker could not be moved");
        root.recordHistory(document, updated.document, "Move timeline marker");
        error = "";
        return true;
    }

    function updateMarker(markerId, changes) {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const updated = MarkerEdit.update(document, markerId, changes || {});
        if (!updated.accepted)
            return reject(updated.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(updated.document)))
            return reject(WallpaperProjectService.error || "Marker could not be updated");
        root.recordHistory(document, updated.document, "Update timeline marker");
        error = "";
        return true;
    }

    function markerActionEdit(markerId, actionId, operation, value) {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        if (["add", "remove", "update"].indexOf(operation) < 0)
            return reject("Unsupported marker action operation");
        const marker = (document.project.markers || []).find(entry => entry.id === String(markerId || ""));
        if (!marker)
            return reject("Timeline marker was not found");
        const result = operation === "add" ? TriggerAction.addAction(marker.actions || [], value) : operation === "remove" ? TriggerAction.removeAction(marker.actions || [], actionId) : TriggerAction.updateAction(marker.actions || [], actionId, value);
        if (!result.accepted)
            return reject(result.error);
        return updateMarker(marker.id, {
            actions: result.actions
        });
    }

    function addMarkerAction(markerId, type) {
        return markerActionEdit(markerId, "", "add", {
            id: nextGestureId() + "-action",
            type: String(type || "")
        });
    }

    function triggerDecisionTrace(nowMs, lastFired) {
        const document = activeDocument();
        return TriggerPolicy.decisionTrace(document?.project?.markers || [], nowMs, lastFired || {});
    }

    function nextTrigger(playheadMs, durationMs, loop) {
        const document = activeDocument();
        return TriggerPolicy.nextTimelineEvent(document?.project?.markers || [], playheadMs, durationMs, loop);
    }

    function trackRemovalReview(trackId) {
        return TrackEdit.removalReview(activeDocument(), String(trackId || ""));
    }

    function removeTrack(trackId, review) {
        if (gestureActive)
            return reject("Finish the timeline gesture before removing a track");
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const removed = TrackEdit.removeTrack(document, String(trackId || ""), review);
        if (!removed.accepted)
            return reject(removed.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(removed.document)))
            return reject(WallpaperProjectService.error || "Timeline track could not be removed");
        root.recordHistory(document, removed.document, "Remove timeline track");
        WallpaperEditorSelectionService.reconcile(removed.document);
        error = "";
        return true;
    }

    function beginGesture(mode, clipId, targetTrackId, pointerStartX, pixelsPerSecond, snapTolerancePx, sourceDurationMs) {
        if (gestureActive)
            return reject("Another timeline gesture is active");
        const document = activeDocument();
        const located = locateClip(document, String(clipId || ""));
        if (!document || !located)
            return reject("Timeline clip was not found");
        const begun = TimelineGesture.begin({
            gestureId: nextGestureId(),
            mode: mode,
            clip: located.clip,
            trackId: String(targetTrackId || located.trackId),
            pointerStartX: pointerStartX,
            pixelsPerSecond: pixelsPerSecond,
            snapTolerancePx: snapTolerancePx,
            projectDurationMs: document.project.durationMs,
            sourceDurationMs: sourceDurationMs
        });
        if (!begun.accepted)
            return reject(begun.error);
        const transition = GestureSession.begin(session, begun.gesture);
        if (!transition.accepted)
            return reject(transition.error);
        session = transition.state;
        error = "";
        return true;
    }

    function updateGesture(pointerX, snappingEnabled) {
        if (!gestureActive)
            return reject("No timeline gesture is active");
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const candidates = Placement.snapCandidates(document.project.tracks, document.project.durationMs, session.gesture.clipId);
        const preview = TimelineGesture.preview(session.gesture, pointerX, candidates, snappingEnabled);
        if (!preview.accepted)
            return reject(preview.error);
        const transition = GestureSession.update(session, preview);
        if (!transition.accepted)
            return reject(transition.error);
        session = transition.state;
        error = "";
        return true;
    }

    function finishGesture() {
        const document = activeDocument();
        if (!document)
            return reject("Active project is unavailable");
        const transition = GestureSession.finish(session);
        if (!transition.accepted)
            return reject(transition.error);
        const applied = applyCommand(document, transition.command);
        if (!applied.accepted)
            return reject(applied.error);
        if (!WallpaperProjectService.upsertJson(JSON.stringify(applied.document)))
            return reject(WallpaperProjectService.error || "Timeline edit could not be saved");
        root.recordHistory(document, applied.document, transition.command.type === "move-clip" ? "Move timeline media" : transition.command.type === "trim-clip-start" ? "Trim timeline media" : "Resize timeline media");
        session = transition.state;
        error = "";
        return true;
    }

    function applyCommand(document, command) {
        if (command.type === "move-clip")
            return TimelineEdit.moveClip(document, command.clipId, command.trackId, command.startMs);
        if (command.type === "trim-clip-start")
            return TimelineEdit.trimClipStart(document, command.clipId, command.startMs, command.sourceDurationMs);
        if (command.type === "resize-clip-end")
            return TimelineEdit.resizeClipEnd(document, command.clipId, command.endMs, command.sourceDurationMs, command.loop);
        return {
            accepted: false,
            error: "Timeline command is unsupported",
            document: null
        };
    }

    function cancelGesture() {
        const transition = GestureSession.cancel(session);
        session = transition.state;
        error = "";
        return true;
    }

    function reject(message) {
        error = String(message || "Timeline operation failed");
        return false;
    }

    function snapshot() {
        return JsonCopy.value({
            gestureActive: gestureActive,
            error: error,
            session: session,
            selection: selection,
            history: {
                canUndo: canUndo,
                canRedo: canRedo,
                depth: history.past.length
            }
        });
    }

    Connections {
        target: WallpaperProjectService
        function onActiveProjectIdChanged() {
            const projectId = WallpaperProjectService.activeProjectId;
            if (projectId !== root.historyProjectId) {
                root.historyProjectId = projectId;
                root.history = CommandHistory.empty(50);
            }
        }
    }
}
