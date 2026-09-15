import QtQuick
import QtQuick.Effects
import qs.core
import qs.panels.wallpaper
import qs.services.wallpaper
import qs.services.wallpaper.projects
import "../services/wallpaper/projects/WallpaperPreviewState.js" as WallpaperPreviewState

Rectangle {
    id: root

    required property var projectPlan
    required property string screenName
    property int positionMs: 0
    property bool enabledPreview: true
    property bool playing: false
    property bool scrubbing: false
    property int previewPositionMs: positionMs
    property bool loopEnabled: false
    property int loopStartMs: 0
    property int loopEndMs: 0
    property double clockStartedAtMs: 0
    readonly property int effectivePositionMs:
        playing ? previewPositionMs : positionMs

    function previewState() {
        return {
            durationMs: Number(root.projectPlan?.durationMs) || 0,
            positionMs: root.previewPositionMs,
            playing: root.playing,
            loopEnabled: root.loopEnabled,
            loopStartMs: root.loopStartMs,
            loopEndMs: root.loopEndMs
        }
    }

    function playPreview() {
        const next = WallpaperPreviewState.play(root.previewState())
        root.previewPositionMs = next.positionMs
        root.playing = next.playing
        return root.playing
    }

    function pausePreview() {
        const next = WallpaperPreviewState.pause(root.previewState())
        root.previewPositionMs = next.positionMs
        root.playing = false
    }

    function togglePlayback() {
        if (root.playing) {
            root.pausePreview()
            return false
        }
        return root.playPreview()
    }

    function seekPreview(nextPositionMs) {
        const next = WallpaperPreviewState.seek(root.previewState(),
            nextPositionMs)
        root.previewPositionMs = next.positionMs
        if (!root.playing)
            root.positionMs = next.positionMs
        else
            root.playing = next.playing
    }

    function toggleLoop() {
        const duration = Number(root.projectPlan?.durationMs) || 0
        const next = WallpaperPreviewState.setLoop(
            root.previewState(), !root.loopEnabled, root.loopStartMs,
            root.loopEndMs > root.loopStartMs ? root.loopEndMs : duration)
        root.loopStartMs = next.loopStartMs
        root.loopEndMs = next.loopEndMs
        root.loopEnabled = next.loopEnabled
        root.previewPositionMs = next.positionMs
        return root.loopEnabled
    }

    function setLoopRegion(startMs, endMs) {
        const next = WallpaperPreviewState.setLoop(root.previewState(),
            root.loopEnabled, startMs, endMs)
        root.loopStartMs = next.loopStartMs
        root.loopEndMs = next.loopEndMs
        root.loopEnabled = next.loopEnabled
        root.previewPositionMs = next.positionMs
        return root.loopEnabled
    }

    readonly property var frame: WallpaperPreviewState.frameAt(
        root.projectPlan, {
            durationMs: root.projectPlan?.durationMs || 0,
            positionMs: root.effectivePositionMs
        }, root.screenName)[0] || null
    readonly property var targetMedia: root.frame?.media || ({})
    readonly property string targetPath: String(root.frame?.path || "")
    readonly property string targetBackend: String(root.frame?.backend || "")
    readonly property string posterPath: {
        if (root.targetPath.length === 0) return ""
        const record = WallpaperPosterService.recordFor(root.targetPath)
        return record?.state === "ready" || record?.stale
            ? String(record.posterPath || "") : ""
    }

    radius: Design.editorSectionRadius
    color: Qt.rgba(1, 1, 1, 0.025)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.045)
    clip: true

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSpreadAtMin: 1
        maskThresholdMin: 0.5
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
                width: root.width
                height: root.height
                radius: root.radius
                color: "white"
            }
        }
    }

    onPositionMsChanged: {
        if (!root.playing)
            root.previewPositionMs = root.positionMs
    }

    onPlayingChanged: {
        if (root.playing) {
            root.clockStartedAtMs = Date.now()
        } else {
            root.clockStartedAtMs = 0
        }
    }

    Timer {
        interval: 33
        repeat: true
        running: root.playing && root.visible && root.projectPlan?.durationMs > 0
        onTriggered: {
            const now = Date.now()
            const elapsed = root.clockStartedAtMs > 0
                ? Math.max(0, now - root.clockStartedAtMs) : interval
            root.clockStartedAtMs = now
            const next = WallpaperPreviewState.advance(
                root.previewState(), elapsed)
            root.previewPositionMs = next.state.positionMs
            if (next.reachedEnd)
                root.playing = false
        }
    }

    WallpaperRendererHost {
        id: renderer
        anchors.fill: parent
        visible: root.enabledPreview && root.frame !== null
        targetPath: root.targetPath
        targetMedia: root.targetMedia
        targetBackend: root.targetBackend
        targetPosterPath: root.posterPath
        screenName: root.screenName
        renderScale: 1
        retainCurrentOnUnavailable: false
        previewMode: true
        lifecycleNamespace: "editor-preview"
        previewPlaying: root.playing
        previewPositionMs: root.effectivePositionMs
    }

    VideoScrubPreview {
        id: scrubPreview
        anchors.fill: parent
        visible: root.scrubbing && root.targetBackend === "video"
            && visualReady
        active: root.scrubbing && root.targetBackend === "video"
        path: root.targetPath
        positionMs: root.effectivePositionMs
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 280)
        spacing: 8
        visible: !renderer.visible && !root.scrubbing

        Text {
            width: parent.width
            text: root.projectPlan?.ready === false
                ? "Preparing preview" : "Preview"
            color: Design.text
            horizontalAlignment: Text.AlignHCenter
            font.family: Design.fontText
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: root.projectPlan?.ready === false
                ? "Media is still being inspected."
                : root.projectPlan?.durationMs > 0
                    ? "Move the playhead over a media clip."
                    : "Add media to begin previewing."
            color: Design.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Design.fontText
            font.pixelSize: 11
        }
    }

    Text {
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 280)
        text: root.frame && !renderer.visualReady
            ? (root.targetBackend === "video"
                ? "Preparing video preview…"
                : "Preparing media preview…")
            : ""
        color: Design.textMuted
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.family: Design.fontText
        font.pixelSize: 11
        visible: root.frame !== null && !renderer.visualReady && !root.scrubbing
    }

    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        text: root.frame ? root.frame.name || root.targetPath.split("/").pop() : ""
        color: Design.textMuted
        font.family: Design.fontText
        font.pixelSize: 10
        elide: Text.ElideRight
        visible: root.frame !== null
    }
}
