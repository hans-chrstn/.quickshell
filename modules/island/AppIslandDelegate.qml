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
        spacing: 4

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
                sourceSize: Qt.size(FrameConfig.appIslandIconSize * 2, FrameConfig.appIslandIconSize * 2)
                source: Quickshell.iconPath(app.icon)
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
        preventStealing: false
        onClicked: app.execute()
    }
}
