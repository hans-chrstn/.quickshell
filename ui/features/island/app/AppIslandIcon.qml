import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import qs.ui.shared.effects

Item {
    id: root
    
    property var app: null
    property bool isHovered: false
    property bool isRunning: false
    property real visualOffset: 0
    property int iconSize: ThemeManager.appIslandIconSize
    
    Layout.preferredWidth: iconSize
    Layout.preferredHeight: iconSize
    Layout.alignment: Qt.AlignHCenter

    readonly property real mouseX: hHandler.point.position.x
    readonly property real mouseY: hHandler.point.position.y
    readonly property real relX: (mouseX / width) - 0.5
    readonly property real relY: (mouseY / height) - 0.5

    HoverHandler {
        id: hHandler
    }
    
    transform: [
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: root.isHovered ? -root.relY * 20 : 0
            Behavior on angle { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutCubic 
                } 
            }
        },
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: root.isHovered ? root.relX * 20 : 0
            Behavior on angle { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutCubic 
                } 
            }
        },
        Translate {
            x: root.isHovered ? root.relX * 6 : 0
            y: root.isHovered ? root.relY * 6 : 0
            Behavior on x { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on y { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutCubic 
                } 
            }
        }
    ]
    
    Rectangle {
        id: shadow
        anchors.fill: parent
        radius: 14
        color: ThemeManager.accentColor
        opacity: root.isHovered ? ThemeManager.visualHighlightOpacity * 4 : ThemeManager.visualHighlightOpacity
        scale: root.isHovered ? 0.95 : 0.85
        
        transform: Translate {
            x: root.isHovered ? -root.relX * 12 : 0
            y: root.isHovered ? 18 - root.relY * 8 : 4
            Behavior on x { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutExpo 
                } 
            }
            Behavior on y { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutExpo 
                } 
            }
        }
        
        z: -1
        
        layer.enabled: root.isHovered
        layer.effect: MultiEffect { 
            blurEnabled: true
            blur: 0.5 
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

    ClippingRectangle {
        id: iconContainer
        anchors.fill: parent
        radius: 12
        color: "transparent"

        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * 2, height * 2)

        Rectangle {
            id: fallbackBackground
            anchors.fill: parent
            radius: 12
            color: ThemeManager.surfaceVariantColor
            visible: appIcon.status !== Image.Ready
            
            StyledLabel {
                anchors.centerIn: parent
                text: root.app ? root.app.name.substring(0, 1).toUpperCase() : "?"
                type: "title"
                font.weight: Font.Black
                opacity: 0.5
            }
        }

        Image {
            id: appIcon
            anchors.fill: parent
            asynchronous: true
            sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2) 
            smooth: true
            mipmap: true
            
            source: {
                if (!root.app || !root.app.icon) {
                    return ""
                }
                if (root.app.icon.startsWith("/")) {
                    return "file://" + root.app.icon
                }
                return Quickshell.iconPath(root.app.icon)
            }
            
            fillMode: Image.PreserveAspectFit
            opacity: status === Image.Ready ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        SpecularHighlight {
            id: specular
            anchors.fill: parent
            intensity: root.isHovered ? 0.5 : 0.0
            mousePos: Qt.vector2d(root.mouseX / width, root.mouseY / height)
        }
    }
    
    Rectangle {
        id: runningIndicator
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
