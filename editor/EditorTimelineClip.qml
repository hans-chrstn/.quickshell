import QtQuick
import qs.core

Rectangle {
    id: root

    required property var clipData
    required property var assetData
    property bool selected: false
    signal activated(int modifiers)
    signal doubleActivated(real localX, int modifiers)
    signal contextRequested(real localX, real localY, int modifiers)
    property double lastTapMs: 0

    readonly property string assetKind: String(assetData?.kind || "unknown")
    readonly property color accent: assetKind === "video" ? Design.blue : assetKind === "animated-image" ? Design.yellow : assetKind === "audio" ? Design.green : Design.textMuted

    radius: 8
    color: Qt.rgba(accent.r, accent.g, accent.b, selected ? 0.28 : 0.18)
    border.width: selected ? 1.5 : 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, selected ? 0.9 : 0.48)
    opacity: clipData?.enabled === false ? 0.48 : 1
    clip: true

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: root.accent
        opacity: 0.9
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
    TapHandler {
        id: primaryTap

        acceptedButtons: Qt.LeftButton
        onTapped: eventPoint => {
            const now = Date.now()
            root.activated(primaryTap.point.modifiers)
            if (now - root.lastTapMs <= 320)
                root.doubleActivated(eventPoint.position.x,
                    primaryTap.point.modifiers)
            root.lastTapMs = now
        }
    }
    TapHandler {
        id: contextTap

        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => root.contextRequested(eventPoint.position.x, eventPoint.position.y, contextTap.point.modifiers)
    }
}
