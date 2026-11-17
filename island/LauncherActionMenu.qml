import QtQuick
import qs.components
import qs.core

Rectangle {
    id: root

    required property var result
    signal actionSelected(string appId, string actionId)

    width: 206
    height: Math.min(result.actions?.length || 0, 6) * Design.launcherActionHeight + Design.space12
    radius: Design.radiusGrouped
    color: Theme.glassPanelExpanded
    border.color: Theme.glassPanelStroke
    clip: true

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: Design.space6
        model: root.result.actions || []
        clip: true
        spacing: 0
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData
            width: list.width
            height: Design.launcherActionHeight
            radius: Design.radiusControl
            color: actionPointer.containsMouse ? Theme.fillElevated : "transparent"

            AppIcon {
                visible: Boolean(modelData.icon)
                x: Design.space8
                anchors.verticalCenter: parent.verticalCenter
                name: modelData.name
                icon: modelData.icon
                iconSize: 17
            }

            Text {
                x: modelData.icon ? 33 : Design.space12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - Design.space8
                text: modelData.name
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            MouseArea {
                id: actionPointer
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionSelected(root.result.id, modelData.id)
                Accessible.role: Accessible.Button
                Accessible.name: modelData.name + " for " + root.result.title
            }
        }
    }
}
