import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.features.island.app

Item {
    id: appDelegate

    width: ThemeManager.appIslandDelegateWidth
    height: ThemeManager.appIslandDelegateHeight

    property bool isIslandExpanded: false
    property var app: model ? model.app : null

    readonly property bool isHovered: hHandler.hovered || contextMenuLoader.active
    readonly property bool isRunning: (appDelegate.app && typeof NiriManager !== "undefined") ? NiriManager.isApplicationRunning(appDelegate.app.id) : false
    
    readonly property real visualOffset: {
        if (!PathView.view) {
            return 0
        }
        let count = PathView.view.count
        let dist = Math.abs(index - PathView.view.currentIndex)
        return Math.min(dist, count - dist)
    }
    
    property real cascadeY: 60
    property real cascadeRotation: 0
    property real cascadeOpacity: 0.0

    property real animScale: isHovered ? 1.25 : 1.0
    Behavior on animScale { 
        NumberAnimation { 
            duration: 450
            easing.type: Easing.OutBack
            easing.overshoot: 1.0 
        } 
    }

    property real animLift: isHovered ? -12 : 0
    Behavior on animLift { 
        NumberAnimation { 
            duration: 450
            easing.type: Easing.OutBack
            easing.overshoot: 1.0 
        } 
    }

    states: [
        State {
            name: "expanded"
            when: appDelegate.isIslandExpanded
            PropertyChanges { 
                target: appDelegate
                cascadeY: 0
                cascadeRotation: 0
                cascadeOpacity: 1.0 
            }
        },
        State {
            name: "collapsed"
            when: !appDelegate.isIslandExpanded
            PropertyChanges { 
                target: appDelegate
                cascadeY: 60
                cascadeRotation: (index % 2 === 0 ? 10 : -10)
                cascadeOpacity: 0.0 
            }
        }
    ]

    transitions: [
        Transition {
            from: "collapsed"
            to: "expanded"
            SequentialAnimation {
                PauseAnimation { 
                    duration: visualOffset * 80 
                }
                ParallelAnimation {
                    NumberAnimation { 
                        property: "cascadeY"
                        duration: 500
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.8 
                    }
                    NumberAnimation { 
                        property: "cascadeRotation"
                        duration: 600
                        easing.type: Easing.OutBack
                        easing.overshoot: 2.0 
                    }
                    NumberAnimation { 
                        property: "cascadeOpacity"
                        duration: 300 
                    }
                }
            }
        },
        Transition {
            from: "expanded"
            to: "collapsed"
            ParallelAnimation {
                NumberAnimation { 
                    property: "cascadeY"
                    duration: 200 
                }
                NumberAnimation { 
                    property: "cascadeRotation"
                    duration: 200 
                }
                NumberAnimation { 
                    property: "cascadeOpacity"
                    duration: 200 
                }
            }
        }
    ]

    opacity: cascadeOpacity * PathView.itemOpacity
    z: appDelegate.isIslandExpanded ? (100 - visualOffset) : 0

    HoverHandler {
        id: hHandler
        cursorShape: Qt.PointingHandCursor
    }

    ColumnLayout {
        id: mainLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        
        transform: [
            Scale {
                origin.x: appDelegate.width / 2
                origin.y: appDelegate.height / 2
                xScale: (mouseArea.pressed ? 0.9 : 1.0) * animScale
                yScale: xScale
            },
            Translate {
                y: animLift + cascadeY
            },
            Rotation {
                origin.x: appDelegate.width / 2
                origin.y: appDelegate.height / 2
                angle: cascadeRotation
            }
        ]

        Item {
            Layout.preferredWidth: Math.max(iconComp.Layout.preferredWidth, nameText.implicitWidth)
            Layout.preferredHeight: iconComp.Layout.preferredHeight + nameText.implicitHeight + mainLayout.spacing
            Layout.alignment: Qt.AlignHCenter

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                
                onClicked: (mouse) => {
                    if (!appDelegate.app) {
                        return
                    }
                    if (mouse.button === Qt.RightButton) {
                        if (!contextMenuLoader.item) {
                            contextMenuLoader.active = true
                        }
                        if (contextMenuLoader.item) {
                            contextMenuLoader.item.popup()
                        }
                    } else {
                        if (appDelegate.isRunning) {
                            NiriManager.focusApplication(appDelegate.app.id)
                        } else {
                            appDelegate.app.execute()
                        }
                    }
                }
            }
            
            Loader {
                id: contextMenuLoader
                active: false
                sourceComponent: menuComponent
            }

            Component {
                id: menuComponent
                AppIslandContextMenu {
                    app: appDelegate.app
                    delegateRoot: appDelegate
                    onClosed: {
                        contextMenuLoader.active = false
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                AppIslandIcon {
                    id: iconComp
                    app: appDelegate.app
                    isHovered: appDelegate.isHovered
                    isRunning: appDelegate.isRunning
                    visualOffset: appDelegate.visualOffset
                }

                StyledLabel {
                    id: nameText
                    text: appDelegate.app ? appDelegate.app.name : ""
                    type: "caption"
                    font.weight: Font.DemiBold
                    font.pixelSize: 10
                    Layout.preferredWidth: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elideMode: Text.ElideRight
                    opacity: PathView.isCurrentItem ? 1.0 : 0.6
                }
            }
        }
    }
}
