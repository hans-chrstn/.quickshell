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
import "./leftdashboard/components"

Item {
    id: root

    property bool active: false
    property int currentPage: 0
    property var pages: []
    property bool suppressDismiss: false
    property var chronoEngine: null

    property bool entryActive: false
    readonly property bool showContent: {
        return active && entryActive
    }

    Timer {
        id: entryTimer
        interval: 50
        running: true
        onTriggered: {
            root.entryActive = true
        }
    }

    property int topFilletXOffset: 0
    property int topFilletYOffset: 0
    property int bottomFilletXOffset: 0
    property int bottomFilletYOffset: 15

    width: 400
    height: parent.height
    x: {
        if (active) {
            return 0
        }
        return -width
    }
    z: 5

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: true
        onPressed: (mouse) => {
            mouse.accepted = false
        }
    }

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
            when: {
                return !root.showContent
            }

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
                    targets: [
                        backgroundLayer, 
                        dashboardContentArea
                    ]
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
                        targets: [
                            backgroundLayer, 
                            dashboardContentArea
                        ]
                        property: "opacity"
                        duration: 150
                    }
                }

                ScriptAction {
                    script: {
                        if (parent && parent.parent && typeof parent.parent.finalizeClose === "function") {
                            parent.parent.finalizeClose()
                        }
                    }
                }
            }
        }
    ]

    DashboardBackground {
        id: backgroundLayer
        opacity: 0
        topFilletXOffset: root.topFilletXOffset
        topFilletYOffset: root.topFilletYOffset
        bottomFilletXOffset: root.bottomFilletXOffset
        bottomFilletYOffset: root.bottomFilletYOffset
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
                active: root.active
                chronoEngine: root.chronoEngine
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
