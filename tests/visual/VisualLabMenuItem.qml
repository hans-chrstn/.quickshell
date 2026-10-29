import QtQuick

Item {
    id: root

    required property var action
    property bool highlighted: false
    signal hovered
    signal triggered

    readonly property bool actionEnabled: action?.enabled !== false
    readonly property bool destructive: action?.destructive === true

    implicitHeight: 38 + (action?.separatorBefore === true ? 9 : 0)
    opacity: actionEnabled ? 1 : 0.34

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 1
        visible: root.action?.separatorBefore === true
        color: "#16ffffff"
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 36
        radius: 10
        color: root.highlighted && root.actionEnabled ? root.destructive ? "#24ff453a" : "#15ffffff" : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }

        VisualLabControlGlyph {
            id: actionGlyph

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
            }
            width: 16
            height: 16
            iconKind: String(root.action?.iconKind || "diamond")
            glyphColor: root.destructive ? "#ffff6259" : root.highlighted ? "#f0f0f2" : "#9a9aa2"
        }

        Text {
            anchors {
                left: actionGlyph.right
                right: shortcutText.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            text: String(root.action?.label || "")
            color: root.destructive ? "#ffff6259" : "#ececef"
            elide: Text.ElideRight
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        Text {
            id: shortcutText

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 11
            }
            text: String(root.action?.shortcut || "")
            color: "#686870"
            font.family: "SF Pro Text"
            font.pixelSize: 9
        }
    }

    HoverHandler {
        enabled: root.actionEnabled
        onHoveredChanged: {
            if (hovered)
                root.hovered();
        }
    }

    TapHandler {
        enabled: root.actionEnabled
        onTapped: root.triggered()
    }
}
