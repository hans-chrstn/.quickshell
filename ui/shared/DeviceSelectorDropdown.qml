import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root

    property var model: []
    property int currentId: -1
    property string icon: ""

    signal deviceSelected(int deviceId, var deviceData)

    implicitHeight: triggerButton.height

    BaseButton {
        id: triggerButton
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        cornerRadius: 6

        onClicked: {
            menuLoader.active = true
        }

        StyledLabel {
            anchors.centerIn: parent
            width: parent.width - 16
            text: {
                if (root.currentId === -1) {
                    return root.icon + " Default (Global)"
                }
                for (let i = 0; i < root.model.length; i++) {
                    if (root.model[i].id === root.currentId) {
                        return root.icon + " " + (root.model[i].name || "Device")
                    }
                }
                return root.icon + " Default (Global)"
            }
            type: "caption"
            font.pixelSize: 10
            elideMode: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            opacity: parent.isHovered ? 1.0 : 0.7
        }
    }

    Loader {
        id: menuLoader
        active: false
        sourceComponent: menuComponent

        onLoaded: {
            item.popup()
        }
    }

    Component {
        id: menuComponent

        BaseContextMenu {
            id: popupMenu
            width: triggerButton.width
            x: 0
            y: triggerButton.height
            onOpened: ViewManager.dashboardContentHovered = true

            onClosed: {
                menuLoader.active = false
            }

            ListView {
                id: deviceList
                implicitHeight: Math.min(root.model.length * 38 + 8, 220)
                spacing: 4
                clip: true
                interactive: contentHeight > height
                model: root.model
                width: triggerButton.width

                delegate: BaseButton {
                    width: deviceList.width
                    height: 36
                    cornerRadius: 4

                    onClicked: {
                        root.deviceSelected(modelData.id, modelData)
                        popupMenu.close()
                    }

                    StyledLabel {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        text: root.icon + " " + (modelData.name || "Device")
                        type: "caption"
                        font.pixelSize: 10
                        font.weight: modelData.id === root.currentId ? Font.Bold : Font.Normal
                        elideMode: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        horizontalAlignment: Text.AlignHCenter
                        opacity: modelData.id === root.currentId ? 1.0 : 0.75
                    }
                }
            }
        }
    }
}
