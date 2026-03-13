import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.shared.effects
import qs.ui.shared.shapes
import "./leftdashboard"

Item {
    id: root

    property bool active: DashboardManager.active
    property bool entryActive: false
    readonly property bool showContent: active && entryActive

    Timer {
        id: entryTimer
        interval: 50
        running: true
        onTriggered: root.entryActive = true
    }

    property int topFilletXOffset: 0
    property int topFilletYOffset: 0
    property int bottomFilletXOffset: 0
    property int bottomFilletYOffset: 15

    width: 400
    height: parent.height
    x: active ? 0 : -width
    z: 5

    onActiveChanged: {
        if (active) {
            SoundManager.playExpand()
        } else {
            SoundManager.playCollapse()
        }
    }

    states: [
        State {
            name: "active"
            when: root.showContent

            PropertyChanges {
                target: root
                x: 0
            }

            PropertyChanges {
                target: backgroundLayer
                opacity: 1
            }

            PropertyChanges {
                target: dashboardContentArea
                opacity: 1
            }
        },
        State {
            name: "inactive"
            when: !root.showContent

            PropertyChanges {
                target: root
                x: -root.width
            }

            PropertyChanges {
                target: backgroundLayer
                opacity: 0
            }

            PropertyChanges {
                target: dashboardContentArea
                opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            from: "inactive"
            to: "active"

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "x"
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing
                }

                NumberAnimation {
                    targets: [backgroundLayer, dashboardContentArea]
                    property: "opacity"
                    duration: 150
                }

                NumberAnimation {
                    target: dashboardContentArea
                    property: "x"
                    from: -30
                    to: 0
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing
                }
            }
        },
        Transition {
            from: "active"
            to: "inactive"

            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "x"
                        duration: ThemeManager.animationDuration
                        easing.type: ThemeManager.animationEasing
                    }

                    NumberAnimation {
                        targets: [backgroundLayer, dashboardContentArea]
                        property: "opacity"
                        duration: 150
                    }
                }

                ScriptAction {
                    script: DashboardManager.finalizeClose()
                }
            }
        }
    ]

    HoverHandler {
        id: dashboardHover

        onHoveredChanged: {
            if (!hovered) {
                DashboardManager.requestDismiss()
            } else {
                DashboardManager.cancelDismiss()
            }
        }
    }

    Item {
        id: backgroundLayer
        anchors.fill: parent
        opacity: 0

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

    Item {
        id: dashboardContentArea
        anchors.fill: parent
        opacity: 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ThemeManager.globalThickness
            spacing: 0

            DashboardSidebar {
                Layout.fillHeight: true
            }

            DashboardContent {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
