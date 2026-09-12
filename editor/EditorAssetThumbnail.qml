import QtQuick
import qs.components.media
import qs.services.wallpaper.projects

Item {
    id: root

    required property var asset
    required property string workspaceId
    property real cornerRadius: 10
    readonly property var derivative: WallpaperDraftDerivativeService.recordFor(
        workspaceId, String(asset?.id || ""), "thumbnail")
    readonly property bool previewReady: thumbnail.previewReady

    property string requestedWorkspaceId: ""
    property string requestedAssetId: ""

    function release() {
        if (requestedWorkspaceId.length > 0 && requestedAssetId.length > 0)
            WallpaperDraftDerivativeService.cancel(requestedWorkspaceId,
                requestedAssetId, "thumbnail")
        requestedWorkspaceId = ""
        requestedAssetId = ""
    }

    function synchronizeDemand() {
        const nextWorkspace = String(workspaceId || "")
        const nextAsset = String(asset?.id || "")
        if (requestedWorkspaceId === nextWorkspace
                && requestedAssetId === nextAsset) return
        release()
        if (nextWorkspace.length === 0 || nextAsset.length === 0) return
        if (WallpaperDraftDerivativeService.request(
                nextWorkspace, nextAsset, "thumbnail")) {
            requestedWorkspaceId = nextWorkspace
            requestedAssetId = nextAsset
        }
    }

    Component.onCompleted: synchronizeDemand()
    Component.onDestruction: release()
    onWorkspaceIdChanged: synchronizeDemand()
    onAssetChanged: synchronizeDemand()

    MediaThumbnail {
        id: thumbnail
        anchors.fill: parent
        record: root.asset?.media || ({})
        cornerRadius: root.cornerRadius
        preferredPreviewPath: root.derivative.state === "ready"
            ? String(root.derivative.outputPath || "") : ""
        posterRequestsEnabled: false
    }
}
