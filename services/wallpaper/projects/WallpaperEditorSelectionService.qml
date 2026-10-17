pragma Singleton

import QtQuick
import Quickshell
import "../../../core/JsonCopy.js" as JsonCopy
import "WallpaperEditorSelection.js" as EditorSelection

Singleton {
    id: root

    property var selection: EditorSelection.empty("")
    readonly property string kind: selection.kind
    readonly property string selectedAssetId: kind === "asset" ? selection.assetId : ""
    readonly property string selectedMarkerId: kind === "marker" ? selection.markerId : ""
    readonly property var timelineSelection: EditorSelection.timelineState(selection)
    readonly property int projectRevision: WallpaperProjectService.revision

    function activeDocument() {
        const id = WallpaperProjectService.activeProjectId;
        return id.length > 0 ? WallpaperProjectService.projectSnapshot(id) : null;
    }

    function reconcile(document) {
        selection = EditorSelection.normalize(selection, document === undefined ? activeDocument() : document);
        return selection.kind !== "none";
    }

    function clear() {
        selection = EditorSelection.empty(WallpaperProjectService.activeProjectId);
    }

    function clearKind(expectedKind) {
        if (kind !== String(expectedKind || ""))
            return false;
        clear();
        return true;
    }

    function selectAsset(assetId) {
        selection = EditorSelection.selectAsset(activeDocument(), assetId);
        return kind === "asset";
    }

    function selectMarker(markerId, toggle) {
        selection = EditorSelection.selectMarker(selection, activeDocument(), markerId, toggle !== false);
        return kind === "marker";
    }

    function selectTrack(trackId) {
        selection = EditorSelection.selectTrack(selection, activeDocument(), trackId);
        return kind === "track";
    }

    function selectClip(trackId, clipId, mode) {
        selection = EditorSelection.selectClip(selection, activeDocument(), trackId, clipId, mode);
        return kind === "clips";
    }

    function selectAllClips() {
        selection = EditorSelection.selectAllClips(activeDocument());
        return kind === "clips";
    }

    function snapshot() {
        return JsonCopy.value(selection);
    }

    onProjectRevisionChanged: reconcile()

    Connections {
        target: WallpaperProjectService
        function onActiveProjectIdChanged() {
            root.selection = EditorSelection.empty(WallpaperProjectService.activeProjectId);
        }
    }
}
