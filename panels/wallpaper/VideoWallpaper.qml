import QtQuick
import qs.components.lifecycle
import qs.core

Item {
    id: root

    required property string path
    required property string screenName
    property string lifecycleKey: screenName
    property string posterPath: ""
    readonly property bool playbackRequested:
        playbackPolicy.playbackRequested
    readonly property bool playingAllowed:
        playbackPolicy.playbackAllowed
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
    readonly property bool posterReady: posterImage.status === Image.Ready
    readonly property bool visualReady: firstFrameReady || posterReady

    readonly property string state: decoder.item ? decoder.item.state
        : decoderRetained ? "loading" : "ready"
    readonly property string error: decoder.item ? decoder.item.error : ""
    readonly property bool suspended: playbackPolicy.suspended
    readonly property string suspendedReason:
        playbackPolicy.suspendedReason

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

    onPlaybackRequestedChanged: {
        if (playbackRequested) {
            adaptiveEligibilityTimer.stop()
            adaptiveEvictionEligible = false
        } else {
            adaptiveEligibilityTimer.restart()
        }
    }
    onPlayingAllowedChanged: applyPlaybackPolicy()
    Component.onCompleted: applyPlaybackPolicy()

    WallpaperPlaybackPolicy {
        id: playbackPolicy
        screenName: root.screenName
    }

    Image {
        id: posterImage
        anchors.fill: parent
        source: LocalUrl.fromPath(root.posterPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.firstFrameReady && status === Image.Ready
    }

    LifecycleLoader {
        id: decoder
        anchors.fill: parent
        resourceId: "wallpaper.video-decoder." + root.lifecycleKey
        owner: "wallpaper.video." + root.lifecycleKey
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

}
