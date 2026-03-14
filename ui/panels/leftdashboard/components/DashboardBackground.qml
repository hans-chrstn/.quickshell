import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.ui.shared.shapes

Item {
    id: root

    property int topFilletXOffset: 0
    property int topFilletYOffset: 0
    property int bottomFilletXOffset: 0
    property int bottomFilletYOffset: 15

    anchors.fill: parent

    Rectangle {
        id: bgRect
        anchors.fill: parent
        anchors.leftMargin: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
        opacity: 1.0

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop { 
                    position: 0.0 
                    color: Qt.rgba(1, 1, 1, 0.02) 
                }

                GradientStop { 
                    position: 0.1 
                    color: "transparent" 
                }

                GradientStop { 
                    position: 0.9 
                    color: "transparent" 
                }

                GradientStop { 
                    position: 1.0 
                    color: Qt.rgba(0, 0, 0, 0.1) 
                }
            }
        }
    }

    InvertedCorner {
        id: topFillet
        anchors.top: parent.top
        anchors.topMargin: root.topFilletYOffset
        anchors.left: bgRect.right
        anchors.leftMargin: root.topFilletXOffset
        cornerRadius: ThemeManager.dynamicIslandCornerRadius
        cornerBackgroundColor: ThemeManager.backgroundColor
        visualRotation: 270
        z: 100
    }

    InvertedCorner {
        id: bottomFillet
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomFilletYOffset
        anchors.left: bgRect.right
        anchors.leftMargin: root.bottomFilletXOffset
        cornerRadius: ThemeManager.dynamicIslandCornerRadius
        cornerBackgroundColor: ThemeManager.backgroundColor
        visualRotation: 180
        z: 100
    }
}
