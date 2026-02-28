import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.shared

Rectangle {
    id: root
    
    property string statusIcon: ""
    property real indicatorValue: 0
    property color progressColor: ThemeManager.accentColor
    property bool isPillActive: false
    
    signal valueAdjusted(real value)
    signal iconInteracted()

    radius: ThemeManager.osdPillRadius
    color: ThemeManager.backgroundPrimaryColor
    
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: ThemeManager.surfacePrimaryColor }
                GradientStop { position: 0.4; color: "transparent" }
            }
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"

        Rectangle {
            width: parent.width * 1.5
            height: parent.height
            rotation: -45
            x: -parent.width * 0.2
            y: -parent.height * 0.5
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: ThemeManager.outlineVariantColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
    
    opacity: isPillActive ? 1.0 : 0.0
    scale: isPillActive ? 1.0 : 0.95
    
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Behavior on scale { 
        NumberAnimation { 
            duration: 450
            easing.type: Easing.OutBack
            easing.overshoot: 1.2 
        } 
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 14
        z: 1

        StyledLabel {
            text: root.statusIcon
            type: "icon"
            opacity: iconHoverHandler.hovered ? 1.0 : 0.7
            Behavior on opacity { NumberAnimation { duration: 200 } }
            TapHandler { onTapped: root.iconInteracted() }
            HoverHandler { 
                id: iconHoverHandler
                cursorShape: Qt.PointingHandCursor 
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 16 
            
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 6
                radius: 3
                color: "black"
                opacity: 0.6
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }
            
            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                width: parent.width * MathUtils.clamp(root.indicatorValue, 0, 1)
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.progressColor }
                    GradientStop { position: 1.0; color: Qt.lighter(root.progressColor, 1.3) }
                }
                
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: -2
                    width: 6
                    height: 10
                    radius: 3
                    color: "white"
                    opacity: 0.6
                    visible: root.indicatorValue > 0.05
                    
                    layer.enabled: true
                    layer.effect: MultiEffect { 
                        blurEnabled: true
                        blur: 0.3 
                    }
                }
                
                Behavior on width { 
                    NumberAnimation { 
                        duration: 250
                        easing.type: Easing.OutCubic 
                    } 
                }
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                
                function updateValue(mouse) { 
                    root.valueAdjusted(MathUtils.clamp(mouse.x / width, 0, 1)) 
                }
                onPressed: (mouse) => updateValue(mouse)
                onPositionChanged: (mouse) => { if (pressed) updateValue(mouse) }
            }
        }

        StyledLabel {
            text: Math.round(root.indicatorValue * 100)
            type: "pillValue"
            opacity: 0.3
            Layout.preferredWidth: 25
            horizontalAlignment: Text.AlignRight
        }
    }
}
