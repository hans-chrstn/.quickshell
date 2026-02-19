import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

Item {
    id: delegateRoot

    width: FrameConfig.appIslandDelegateWidth
    height: FrameConfig.appIslandDelegateHeight

    property var app

    opacity: PathView.isCurrentItem ? 1.0 : FrameConfig.appIslandMinOpacity
    scale: PathView.isCurrentItem ? 1.0 : FrameConfig.appIslandMinScale

    Behavior on opacity { NumberAnimation { duration: FrameConfig.appIslandHighlightAnimDuration } }
    Behavior on scale { NumberAnimation { duration: FrameConfig.appIslandHighlightAnimDuration } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Item {
            Layout.preferredWidth: FrameConfig.appIslandIconSize
            Layout.preferredHeight: FrameConfig.appIslandIconSize
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "black"
                opacity: 0.2
                scale: 0.9
                y: 4
                z: -1
            }

            Image {
                id: appIcon
                anchors.fill: parent
                sourceSize: Qt.size(FrameConfig.appIslandIconSize, FrameConfig.appIslandIconSize)
                source: Quickshell.iconPath(app.icon)
                fillMode: Image.PreserveAspectFit
            }
        }

        Item {
            Layout.preferredWidth: FrameConfig.appIslandDelegateWidth - FrameConfig.appIslandDelegateTextMargin
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignHCenter

            Text {
                anchors.fill: parent
                text: app.name
                color: "white"
                font.pixelSize: 11
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                opacity: PathView.isCurrentItem ? 1.0 : 0.7
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: app.execute()
    }
}
