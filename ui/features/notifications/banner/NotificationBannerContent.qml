import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.ui.shared
import qs.core

ClippingRectangle {
    id: root
    
    property var notification: null
    property bool isCloseHovered: hh.hovered
    
    signal closeClicked()
    
    anchors.fill: parent
    radius: 20
    color: ThemeManager.backgroundPrimaryColor
    border.color: ThemeManager.outlinePrimaryColor
    border.width: 1
    
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowOpacity: 0.3
        shadowBlur: 0.4
        shadowVerticalOffset: 2
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: ThemeManager.accentColor
            opacity: 0.1
            
            Text {
                anchors.centerIn: parent
                text: "󰂚"
                color: ThemeManager.accentColor
                font.pixelSize: 20
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                text: root.notification ? root.notification.summary : "Notification"
                color: ThemeManager.contentOnBackgroundColor
                font.weight: Font.Black
                font.pixelSize: 13
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                text: root.notification ? root.notification.body : ""
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.6
                font.pixelSize: 11
                elide: Text.ElideRight
                visible: text !== ""
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: ThemeManager.contentOnBackgroundColor
                opacity: root.isCloseHovered ? 0.8 : 0.3
                font.pixelSize: 16
                Behavior on opacity { 
                    NumberAnimation { 
                        duration: 200 
                    } 
                }
            }
            
            TapHandler { 
                onTapped: root.closeClicked() 
            }
            HoverHandler { 
                id: hh
                cursorShape: Qt.PointingHandCursor 
            }
        }
    }
}
