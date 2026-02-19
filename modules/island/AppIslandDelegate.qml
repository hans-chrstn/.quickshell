import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

Item {
    id: delegateRoot

    width: FrameConfig.appIslandDelegateWidth
    height: FrameConfig.appIslandDelegateHeight

    readonly property var app: model.app

    opacity: PathView.itemOpacity

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4
        scale: mouseArea.pressed ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }

        Item {
            Layout.preferredWidth: FrameConfig.appIslandIconSize
            Layout.preferredHeight: FrameConfig.appIslandIconSize
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "black"
                opacity: 0.4
                scale: 0.85
                y: 6
                z: -1
            }

            Image {
                id: appIcon
                anchors.fill: parent
                sourceSize: Qt.size(FrameConfig.appIslandIconSize, FrameConfig.appIslandIconSize)
                source: app ? Quickshell.iconPath(app.icon) : ""
                fillMode: Image.PreserveAspectFit
            }
        }

        Text {
            text: app ? app.name : ""
            color: "white"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            width: parent.width - 8
            Layout.preferredWidth: parent.width - 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            opacity: PathView.isCurrentItem ? 1.0 : 0.6
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            if (app) {
                app.execute();
            }
        }
    }
}
