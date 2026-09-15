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
import "WallpaperCommandHistory.js" as CommandHistory

Singleton {
    id: root

    property var session: GestureSession.idle("")
    property string error: ""
    property int gestureSequence: 0
    property var selection: TimelineSelection.empty("")
    property var history: CommandHistory.empty(50)
    property string historyProjectId: ""
    readonly property int projectRevision: WallpaperProjectService.revision
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
        selection = TimelineSelection.normalize(selection, result.command.before.project?.tracks || []);
        return true;
    }

    function redo() {
        const result = CommandHistory.redo(history);
        if (!result.command)
            return false;
        if (!root.applyHistoryDocument(result.command.after))
            return false;
        history = result.state;
        selection = TimelineSelection.normalize(selection, result.command.after.project?.tracks || []);
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
        const document = activeDocument();
        if (!document)
            return false;
        selection = TimelineSelection.selectClip(selection, document.project.tracks, String(trackId || ""), String(clipId || ""), String(mode || "replace"));
        error = "";
        return true;
    }

    function selectAllClips() {
        const document = activeDocument();
        if (!document)
            return false;
        const entries = TimelineSelection.entries(document.project.tracks);
        selection = TimelineSelection.normalize({
            trackId: entries[0]?.trackId || "",
            primaryClipId: entries[0]?.clipId || "",
            anchorClipId: entries[0]?.clipId || "",
            clipIds: entries.map(entry => entry.clipId)
        }, document.project.tracks);
        error = "";
        return entries.length > 0;
    }

    function clearSelection() {
        selection = TimelineSelection.empty("");
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
        selection = TimelineSelection.selectTrack(selection, added.document.project.tracks, trackId);
        error = "";
        return true;
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
        selection = TimelineSelection.normalize(selection, removed.document.project.tracks);
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

    onProjectRevisionChanged: {
        const document = activeDocument();
        selection = document ? TimelineSelection.normalize(selection, document.project.tracks) : TimelineSelection.empty("");
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
