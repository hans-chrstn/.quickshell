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
        spacing: FrameConfig.appIslandSpacing

        Image {
            id: appIcon
            width: FrameConfig.appIslandIconSize
            height: FrameConfig.appIslandIconSize
            sourceSize: Qt.size(FrameConfig.appIslandIconSize, FrameConfig.appIslandIconSize)
            Layout.alignment: Qt.AlignHCenter
            source: Quickshell.iconPath(app.icon)
            fillMode: Image.PreserveAspectFit
        }

        Rectangle {
            width: FrameConfig.appIslandDelegateWidth - FrameConfig.appIslandDelegateTextMargin
            height: childrenRect.height
            clip: true
            color: "transparent"
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: app.name
                color: "white"
                font.pixelSize: FrameConfig.appIslandFontSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: app.execute()
    }
}