import QtQuick
import QtQuick.Layouts
import qs.core
import "../services/media/MediaTime.js" as MediaTime

Item {
    id: root

    property var player: null
    property real peak: 0
    property real positionSeconds: 0
    property real previewFraction: 0
    property bool dragging: false
    property real wavePhase: 0
    property real waveLevel: 0
    readonly property bool playing: player?.isPlaying === true
    readonly property bool hasTimeline: player?.positionSupported === true && player?.lengthSupported === true && player.length > 0
    readonly property bool canScrub: hasTimeline && player?.canSeek === true
    readonly property real duration: hasTimeline ? player.length : 0
    readonly property real progress: dragging ? previewFraction : MediaTime.fraction(positionSeconds, duration)
    readonly property color playedColor: Theme.accent
    readonly property color unplayedColor: Theme.textTertiary

    signal seekRequested(real seconds)
    signal seekDeltaRequested(real seconds)

    implicitHeight: 32

    function updatePosition() {
        if (!dragging)
            positionSeconds = player?.positionSupported ? player.position : 0;
    }

    function waveOffset(fraction) {
        const amplitude = playing && !Design.reducedMotion ? Design.mediaScrubBaseAmplitude + waveLevel * Design.mediaScrubPeakAmplitude : 0;
        return amplitude * (Math.sin(fraction * Math.PI * 6 - wavePhase) * 0.7 + Math.sin(fraction * Math.PI * 13 + wavePhase * 0.6) * 0.3);
    }

    function lowerWaveOffset(fraction) {
        const drift = playing && !Design.reducedMotion ? wavePhase * 0.65 : 0;
        return Design.mediaScrubLowerDepth + waveOffset(fraction) * 0.25 + Math.sin(fraction * Math.PI * 5 + drift) * Design.mediaScrubLowerAmplitude;
    }

    onPlayerChanged: {
        dragging = false;
        updatePosition();
    }
    onProgressChanged: waveTrack.requestPaint()
    onPlayingChanged: waveTrack.requestPaint()
    onPlayedColorChanged: waveTrack.requestPaint()
    onUnplayedColorChanged: waveTrack.requestPaint()

    Timer {
        interval: 500
        repeat: true
        running: root.visible && root.player?.isPlaying === true && root.hasTimeline
        onTriggered: root.updatePosition()
    }

    Timer {
        interval: Design.audioLiquidFrameInterval
        repeat: true
        running: root.visible && root.playing && !Design.reducedMotion
        onTriggered: {
            root.wavePhase += Design.audioLiquidPhaseStep;
            root.waveLevel += (Math.max(0, Math.min(1, root.peak)) - root.waveLevel) * Design.audioLiquidResponse;
            waveTrack.requestPaint();
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: Design.space8

        Text {
            Layout.preferredWidth: 39
            horizontalAlignment: Text.AlignRight
            text: root.hasTimeline ? MediaTime.clock(root.dragging ? root.duration * root.previewFraction : root.positionSeconds) : "–:––"
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeCaption
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            Canvas {
                id: waveTrack
                anchors.fill: parent

                function trace(ctx, w, h) {
                    ctx.moveTo(0, h / 2 + root.waveOffset(0));
                    for (let x = 2; x < w; x += 2)
                        ctx.lineTo(x, h / 2 + root.waveOffset(x / w));
                    ctx.lineTo(w, h / 2 + root.waveOffset(1));
                }

                function fillArea(ctx, w, h) {
                    ctx.moveTo(0, h / 2 + root.waveOffset(0));
                    for (let x = 2; x < w; x += 2)
                        ctx.lineTo(x, h / 2 + root.waveOffset(x / w));
                    ctx.lineTo(w, h / 2 + root.waveOffset(1));
                    ctx.lineTo(w, h / 2 + root.lowerWaveOffset(1));
                    for (let x = w - 2; x > 0; x -= 2)
                        ctx.lineTo(x, h / 2 + root.lowerWaveOffset(x / w));
                    ctx.lineTo(0, h / 2 + root.lowerWaveOffset(0));
                    ctx.closePath();
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    if (width <= 0 || height <= 0)
                        return;
                    ctx.lineWidth = Design.mediaScrubStrokeWidth;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    fillArea(ctx, width, height);
                    ctx.fillStyle = Theme.alpha(root.unplayedColor, Design.mediaScrubUnplayedFillOpacity);
                    ctx.fill();
                    ctx.beginPath();
                    trace(ctx, width, height);
                    ctx.strokeStyle = root.unplayedColor;
                    ctx.stroke();
                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(0, 0, width * root.progress, height);
                    ctx.clip();
                    ctx.beginPath();
                    fillArea(ctx, width, height);
                    ctx.fillStyle = Theme.alpha(root.playedColor, Design.mediaScrubPlayedFillOpacity);
                    ctx.fill();
                    ctx.beginPath();
                    trace(ctx, width, height);
                    ctx.strokeStyle = root.playedColor;
                    ctx.stroke();
                    ctx.restore();
                }
            }

            Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * root.progress - width / 2))
                y: parent.height / 2 + root.waveOffset(root.progress) - height / 2
                width: scrub.hovered || root.dragging ? 12 : 8
                height: width
                radius: width / 2
                color: root.canScrub ? Theme.textPrimary : Theme.textTertiary

                Behavior on width {
                    NumberAnimation {
                        duration: Design.motionControlDuration
                        easing.type: Design.motionStandardEasing
                    }
                }
            }

            MouseArea {
                id: scrub
                anchors.fill: parent
                enabled: root.canScrub
                hoverEnabled: true
                cursorShape: root.canScrub ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: mouse => {
                    root.dragging = true;
                    root.previewFraction = Math.max(0, Math.min(1, mouse.x / width));
                    forceActiveFocus();
                }
                onPositionChanged: mouse => {
                    if (root.dragging)
                        root.previewFraction = Math.max(0, Math.min(1, mouse.x / width));
                }
                onReleased: mouse => {
                    root.previewFraction = Math.max(0, Math.min(1, mouse.x / width));
                    root.positionSeconds = root.duration * root.previewFraction;
                    root.dragging = false;
                    root.seekRequested(root.positionSeconds);
                }
                onCanceled: root.dragging = false
                Keys.onLeftPressed: root.seekDeltaRequested(-5)
                Keys.onRightPressed: root.seekDeltaRequested(5)
                Accessible.role: Accessible.Slider
                Accessible.name: "Track position"
                Accessible.description: root.canScrub ? MediaTime.clock(root.positionSeconds) + " of " + MediaTime.clock(root.duration) : "Seeking unavailable"
            }
        }

        Text {
            Layout.preferredWidth: 39
            text: root.hasTimeline ? MediaTime.clock(root.duration) : "–:––"
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeCaption
        }
    }
}
