import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    height: parent.height
    spacing: 6
    
    property string screenName: ""

    Repeater {
        model: NiriService.workspaces
        delegate: Rectangle {
            readonly property bool onCurrentScreen: model.output === root.screenName
            visible: onCurrentScreen
            
            Layout.preferredWidth: visible ? (maWs.containsMouse ? 32 : (model.isActive ? 24 : 8)) : 0
            Layout.preferredHeight: visible ? 6 : 0
            
            radius: 3
            color: model.isFocused ? ThemeService.accentColor : 
                   model.isActive ? Qt.rgba(ThemeService.backgroundContent.r, ThemeService.backgroundContent.g, ThemeService.backgroundContent.b, 0.5) : 
                                    Qt.rgba(ThemeService.backgroundContent.r, ThemeService.backgroundContent.g, ThemeService.backgroundContent.b, 0.2)
            
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            
            MouseArea {
                id: maWs
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NiriService.focusWorkspace(model.id)
            }
        }
    }
}