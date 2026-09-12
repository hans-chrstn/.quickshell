import QtQuick
import QtQuick.Layouts
import qs.core
import qs.editor

Rectangle {
    id: root

    required property var asset
    required property string workspaceId
    property bool selected: false
    signal activated()
    signal contextRequested(real localX, real localY)

    readonly property string extension: {
        const path = asset.resolvedPath || asset.sourcePath || ""
        const name = path.slice(path.lastIndexOf("/") + 1)
        const dot = name.lastIndexOf(".")
        return dot >= 0 ? name.slice(dot + 1).toUpperCase() : "MEDIA"
    }
    readonly property color stateColor: asset.state === "available"
        ? Design.green : asset.state === "pending" ? Design.yellow : Design.red

    implicitHeight: 58
    radius: 13
    color: selected ? Qt.rgba(
        Design.blue.r, Design.blue.g, Design.blue.b, 0.15)
        : hover.hovered ? Qt.rgba(1, 1, 1, 0.055) : "transparent"
    border.width: selected ? 1 : 0
    border.color: Qt.rgba(
        Design.blue.r, Design.blue.g, Design.blue.b, 0.42)

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 9
        spacing: 9

        Rectangle {
            implicitWidth: 40
            implicitHeight: 40
            radius: 11
            color: Qt.rgba(1, 1, 1, 0.065)

            EditorAssetThumbnail {
                id: thumbnail
                anchors.fill: parent
                anchors.margins: 1
                asset: root.asset
                workspaceId: root.workspaceId
                cornerRadius: parent.radius - 1
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 6
                text: root.extension
                color: Design.textMuted
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 8
                font.weight: Font.DemiBold
                visible: !thumbnail.previewReady
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 3
                width: 6
                height: 6
                radius: 3
                color: root.stateColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.asset.name
                color: Design.text
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 11
                font.weight: Font.Medium
            }
            Text {
                Layout.fillWidth: true
                text: root.asset.state === "available"
                    ? root.asset.declaredKind.replace("-", " ")
                    : root.asset.state
                color: Design.textMuted
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 9
                font.capitalization: Font.Capitalize
            }
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => {
            root.activated()
            root.contextRequested(eventPoint.position.x, eventPoint.position.y)
        }
    }
}
