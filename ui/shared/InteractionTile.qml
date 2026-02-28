import QtQuick
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property string tileIcon: ""
    property bool isTileActive: false
    property color activeTileColor: ThemeManager.accentColor
    
    signal tileClicked()
    onClicked: tileClicked()

    width: ThemeManager.controlCenterTileSize
    height: ThemeManager.controlCenterTileSize
    
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        radius: ThemeManager.controlCenterTileRadius
        color: root.isTileActive ? root.activeTileColor : ThemeManager.surfacePrimaryColor
        opacity: root.isTileActive ? 1.0 : (root.isHovered ? 0.8 : 0.5)
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: root.isTileActive || root.isHovered
            shadowOpacity: root.isTileActive ? 0.4 : 0.2
            shadowBlur: 0.3
            shadowVerticalOffset: 2
        }
        
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        StyledLabel {
            anchors.centerIn: parent
            text: root.tileIcon
            type: "icon"
            customColor: root.isTileActive ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            opacity: 1.0
        }
    }
}
