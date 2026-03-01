import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property string tileIcon: ""
    property string tileLabel: ""
    property bool isTileActive: false
    property color activeTileColor: ThemeManager.accentColor
    
    signal tileClicked()
    onClicked: {
        root.tileClicked()
    }

    width: ThemeManager.controlCenterTileSize
    height: ThemeManager.controlCenterTileSize
    
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        radius: ThemeManager.controlCenterTileRadius
        color: root.isTileActive ? root.activeTileColor : ThemeManager.surfacePrimaryColor
        opacity: root.isTileActive ? 1.0 : (root.isHovered ? 0.9 : 0.7)
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: root.isTileActive || root.isHovered
            shadowOpacity: root.isTileActive ? 0.4 : 0.2
            shadowBlur: 0.3
            shadowVerticalOffset: 2
        }
        
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            visible: root.tileLabel !== ""

            StyledLabel {
                Layout.alignment: Qt.AlignHCenter
                text: root.tileIcon
                type: "icon"
                customColor: root.isTileActive ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                opacity: 1.0
            }

            StyledLabel {
                Layout.alignment: Qt.AlignHCenter
                text: root.tileLabel
                type: "caption"
                font.pixelSize: 7
                font.weight: Font.Black
                customColor: root.isTileActive ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                opacity: 0.8
            }
        }

        StyledLabel {
            anchors.centerIn: parent
            visible: root.tileLabel === ""
            text: root.tileIcon
            type: "icon"
            customColor: root.isTileActive ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            opacity: 1.0
        }
    }
}
