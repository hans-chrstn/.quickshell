import QtQuick
import qs.components.lifecycle
import qs.core
import qs.services.power
import qs.services.session
import qs.services.wallpaper

Item {
    id: root

    required property string path
    required property string screenName
    property string posterPath: ""
    readonly property bool occlusionKnown:
        WallpaperOcclusionService.known(screenName)
    readonly property bool occluded: WallpaperOcclusionService.covered(screenName)
    readonly property bool monitorPowerKnown:
        WallpaperMonitorPowerService.known(screenName)
    readonly property bool monitorPowered:
        WallpaperMonitorPowerService.powered(screenName)
    readonly property bool playbackRequested: occlusionKnown && monitorPowerKnown
        && !SessionLockService.locked
        && !PowerStateService.pauseRequested && monitorPowered && !occluded
    property bool playingAllowed: false
    property bool firstFrameReady: false
    property int suspendedPositionMs: 0
    property bool decoderRetained: false
    property bool adaptiveEvictionEligible: false
    property string decoderEvictionReason: "sustained-suspension"
    readonly property int decoderEvictionDelayMs: 30000
    readonly property bool decoderEvicted: !decoderRetained
    readonly property bool decoderLoaded: decoder.item !== null
    readonly property bool playbackActive:
        Boolean(decoder.item?.actuallyPlaying)

    readonly property string state: decoder.item ? decoder.item.state
        : decoderRetained ? "loading" : "ready"
    readonly property string error: decoder.item ? decoder.item.error : ""
    readonly property bool suspended: !playingAllowed
    readonly property string suspendedReason: SessionLockService.locked
        ? "session-locked" : PowerStateService.pauseRequested ? "on-battery"
            : !occlusionKnown || !monitorPowerKnown ? "observing-display"
            : !monitorPowered ? "monitor-off"
            : occluded ? "window-covered"
                : !playingAllowed ? "resuming" : ""

    function reconcilePlaybackRequest() {
        if (playbackRequested) {
            adaptiveEligibilityTimer.stop()
            adaptiveEvictionEligible = false
            resumeTimer.restart()
        } else {
            resumeTimer.stop()
            playingAllowed = false
            adaptiveEligibilityTimer.restart()
            applyPlaybackPolicy()
        }
    }

    function applyPlaybackPolicy() {
        if (playingAllowed) {
            evictionTimer.stop()
            if (!decoderRetained) {
                firstFrameReady = false
                decoderEvictionReason = "sustained-suspension"
                decoderRetained = true
            }
        } else {
            if (decoder.item)
                decoder.item.captureAndPause()
            if (decoderRetained)
                evictionTimer.restart()
            else
                evictionTimer.stop()
        }
    }

    function evictDecoder(reason) {
        if (playingAllowed || !decoderRetained)
            return false
        if (decoder.item)
            decoder.item.captureAndPause()
        firstFrameReady = false
        decoderEvictionReason = String(reason || "sustained-suspension")
        decoderRetained = false
        return true
    }

    onPlaybackRequestedChanged: reconcilePlaybackRequest()
    onPlayingAllowedChanged: applyPlaybackPolicy()

    Timer {
        id: resumeTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.playbackRequested)
                root.playingAllowed = true
        }
    }

    Image {
        anchors.fill: parent
        source: LocalUrl.fromPath(root.posterPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.firstFrameReady && status === Image.Ready
    }

    LifecycleLoader {
        id: decoder
        anchors.fill: parent
        resourceId: "wallpaper.video-decoder." + root.screenName
        owner: "wallpaper.video." + root.screenName
        restorationSource: "VideoWallpaper position and poster state"
        classification: "briefly-warm"
        adaptiveEligible: root.adaptiveEvictionEligible
        estimatedCostUnits: 60
        basePriority: 50
        requestedActive: root.decoderRetained
        usageActive: root.playingAllowed
        retentionReason: root.playingAllowed ? "playback-active"
            : root.decoderRetained ? "suspension-grace-period" : ""
        evictionReason: root.decoderRetained ? ""
            : root.decoderEvictionReason
        sourceComponent: decoderComponent
        onAdaptiveEvictionRequested: reason => root.evictDecoder(reason)
    }

    Component {
        id: decoderComponent
        VideoDecoder {
            path: root.path
            playbackAllowed: root.playingAllowed
            resumePositionMs: root.suspendedPositionMs
            onPositionCaptured: positionMs => {
                root.suspendedPositionMs = positionMs
            }
            onFirstFrameReadyChanged: {
                root.firstFrameReady = firstFrameReady
            }
        }
    }

    Timer {
        id: adaptiveEligibilityTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!root.playbackRequested && root.decoderRetained)
                root.adaptiveEvictionEligible = true
        }
    }

    Timer {
        id: evictionTimer
        interval: root.decoderEvictionDelayMs
        repeat: false
        onTriggered: {
            root.evictDecoder("sustained-suspension")
        }
    }

    Component.onCompleted: {
        SessionLockService.acquire()
        WallpaperOcclusionService.acquire(screenName)
        WallpaperMonitorPowerService.acquire(screenName)
        reconcilePlaybackRequest()
    }
    Component.onDestruction: {
        SessionLockService.release()
        WallpaperOcclusionService.release(screenName)
        WallpaperMonitorPowerService.release(screenName)
    }
}
