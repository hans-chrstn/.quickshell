import QtQuick
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property var clipData
    required property var assetData
    signal activated(int modifiers)
    signal doubleActivated(real localX, int modifiers)
    signal contextRequested(real localX, real localY, int modifiers)
    signal gestureStarted(string mode, real localX)
    signal gestureMoved(real localX)
    signal gestureFinished
    signal gestureCanceled
    property double lastTapMs: 0

    readonly property string assetKind: String(assetData?.kind || "unknown")
    readonly property color accent: assetKind === "video" ? Design.blue : assetKind === "animated-image" ? Design.yellow : assetKind === "audio" ? Design.green : Design.textMuted
    readonly property real edgeZone: Math.min(18, Math.max(8, width * 0.2))

    interactive: false
    accentColor: accent
    baseColor: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
    cornerRadius: 8
    opacity: clipData?.enabled === false ? 0.48 : 1
    clip: true

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        radius: 1
        color: root.accent
        opacity: root.highlighted ? 0.9 : 0
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        radius: 1
        color: root.accent
        opacity: root.highlighted ? 0.9 : 0
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.assetData?.name || root.clipData?.assetId || "Missing media"
            color: Design.text
            elide: Text.ElideRight
            font.family: Design.fontText
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: root.clipData?.loop ? root.assetKind + " · loop" : root.assetKind
            color: Design.textMuted
            elide: Text.ElideRight
            font.family: Design.fontText
            font.pixelSize: 7
        }
    }

    HoverHandler {
        id: hover
    }
    MouseArea {
        id: interaction
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        hoverEnabled: true
        property string mode: "move"
        property real pressX: 0
        property bool dragging: false

        onPressed: mouse => {
            pressX = mouse.x;
            if (mouse.button === Qt.RightButton) {
                root.contextRequested(mouse.x, mouse.y, mouse.modifiers);
                return;
            }
            mode = mouse.x <= root.edgeZone ? "trim-start" : mouse.x >= width - root.edgeZone ? "resize-end" : "move";
            dragging = false;
        }
        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton))
                return;
            if (!dragging && Math.abs(mouse.x - pressX) >= 3) {
                dragging = true;
                root.gestureStarted(mode, pressX);
            }
            if (dragging)
                root.gestureMoved(mouse.x);
        }
        onReleased: mouse => {
            if (mouse.button !== Qt.LeftButton)
                return;
            if (dragging) {
                root.gestureFinished();
                dragging = false;
                return;
            }
            const now = Date.now();
            root.activated(mouse.modifiers);
            if (now - root.lastTapMs <= 320)
                root.doubleActivated(mouse.x, mouse.modifiers);
            root.lastTapMs = now;
        }
        onCanceled: {
            if (dragging)
                root.gestureCanceled();
            dragging = false;
        }
    }
}
