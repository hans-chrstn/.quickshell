import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property var app: null
    property bool isHovered: false
    property bool isRunning: false
    property real visualOffset: 0
    
    Layout.preferredWidth: ThemeManager.appIslandIconSize
    Layout.preferredHeight: ThemeManager.appIslandIconSize
    Layout.alignment: Qt.AlignHCenter
    
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: ThemeManager.accentColor
        opacity: root.isHovered ? ThemeManager.visualHighlightOpacity * 4 : ThemeManager.visualHighlightOpacity
        scale: root.isHovered ? 0.95 : 0.85
        y: root.isHovered ? 18 : 4
        z: -1
        
        layer.enabled: root.isHovered
        layer.effect: MultiEffect { 
            blurEnabled: true
            blur: 0.5 
        }
        
        Behavior on y { 
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutExpo 
            } 
        }
        Behavior on opacity { 
            NumberAnimation { 
                duration: 400 
            } 
        }
        Behavior on scale { 
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutBack 
            } 
        }
    }

    LazyLoader {
        id: iconLoader
        loading: root.visualOffset < 10
        activeAsync: root.visualOffset < 5
        
        Image {
            id: appIcon
            parent: root
            anchors.fill: parent
            sourceSize: Qt.size(ThemeManager.appIslandIconSize * 2, ThemeManager.appIslandIconSize * 2) 
            layer.enabled: root.isHovered
            layer.effect: MultiEffect { 
                brightness: 0.15
                saturation: 0.1 
            }
            source: {
                if (!root.app || !root.app.icon) return ""
                if (root.app.icon.startsWith("/")) return "file://" + root.app.icon
                if (root.app.icon === "utilities-system-monitor" || root.app.icon === "system-run") return ""
                return Quickshell.iconPath(root.app.icon)
            }
            fillMode: Image.PreserveAspectFit
        }
    }
    
    StyledLabel {
        anchors.centerIn: parent
        visible: !iconLoader.item || iconLoader.item.status !== Image.Ready
        text: root.app ? root.app.name.substring(0, 1).toUpperCase() : "?"
        type: "title"
        font.weight: Font.Black
        opacity: 0.2
    }
    
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -6
        width: root.isRunning ? 12 : 0
        height: 4
        radius: 2
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isRunning ? 0.8 : 0.0
        
        Behavior on width { 
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutBack 
            } 
        }
        Behavior on opacity { 
            NumberAnimation { 
                duration: 200 
            } 
        }
    }
}
