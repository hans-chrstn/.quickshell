import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

Item {
    id: root

    property int barHeight: FrameConfig.thickness
    property color barColor: FrameConfig.color
    property bool searchVisible: false
    property bool expanded: false
    property alias isInteracting: root.expanded
    property real blurAmount: 0
    property real radius: FrameConfig.dynamicIslandCornerRadius

    states: [
        State {
            name: "search"
            when: root.searchVisible
            PropertyChanges { target: root; height: FrameConfig.appIslandExpandedHeight + searchBar.height + 10; blurAmount: 0 }
            PropertyChanges { target: islandContentArea; opacity: 1 }
            PropertyChanges { target: searchBar; visible: true; opacity: 1 }
        },
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: root; width: FrameConfig.appIslandExpandedWidth; height: FrameConfig.appIslandExpandedHeight; blurAmount: 0 }
            PropertyChanges { target: islandContentArea; opacity: 1 }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandCollapsedWidth; height: root.barHeight; blurAmount: 0.5 }
            PropertyChanges { target: islandContentArea; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            to: "expanded"
            ParallelAnimation {
                NumberAnimation {
                    properties: "width,height,radius,blurAmount"
                    duration: FrameConfig.animDuration
                    easing.type: FrameConfig.animEasing
                }
                SequentialAnimation {
                    PauseAnimation { duration: FrameConfig.animDuration * 0.7 }
                    NumberAnimation {
                        target: islandContentArea
                        property: "opacity"
                        to: 1
                        duration: 150
                    }
                }
            }
        },
        Transition {
            to: "collapsed"
            SequentialAnimation {
                NumberAnimation {
                    target: islandContentArea
                    property: "opacity"
                    to: 0
                    duration: 100
                }
                ParallelAnimation {
                    NumberAnimation {
                        properties: "width,height,blurAmount"
                        duration: FrameConfig.animDuration
                        easing.type: FrameConfig.animEasing
                    }
                }
            }
        }
    ]

    Item {
        id: islandContainer
        anchors.fill: parent
        
        readonly property bool isStatic: root.width === (root.expanded ? FrameConfig.appIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth)

        Rectangle {
            anchors.fill: islandRect
            radius: root.radius
            color: "black"
            opacity: root.expanded && islandContainer.isStatic ? 0.4 : 0
            visible: opacity > 0
            z: -1
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        RoundedCornerShape {
            anchors.right: islandRect.left
            anchors.rightMargin: -1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth + 1
            height: Math.min(FrameConfig.roundedCornerShapeRadius, Math.max(0, islandRect.height - root.barHeight))
            isLeft: true
            isBottom: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            opacity: islandRect.height > (root.barHeight + 1) ? 1.0 : 0.0
        }

        RoundedCornerShape {
            anchors.left: islandRect.right
            anchors.leftMargin: -1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth + 1
            height: Math.min(FrameConfig.roundedCornerShapeRadius, Math.max(0, islandRect.height - root.barHeight))
            isLeft: false
            isBottom: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            opacity: islandRect.height > (root.barHeight + 1) ? 1.0 : 0.0
        }

        ClippingRectangle {
            id: islandRect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.barColor
            
            topLeftRadius: root.radius
            topRightRadius: root.radius
            bottomLeftRadius: 0
            bottomRightRadius: 0
        }

        Item {
            id: islandContentArea
            anchors.fill: parent
            anchors.bottomMargin: 10
            opacity: 0 
            
            AlphabetScrubber {
                id: alphabetScrubber
                width: parent.width
                anchors.top: parent.top
                onLetterClicked: (letter) => {
                    for (var i = 0; i < appListModel.count; i++) {
                        var app = appListModel.get(i).app;
                        var firstLetter = app.name.substring(0, 1).toUpperCase();
                        if (letter === "#" && !"ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter)) {
                            view.currentIndex = i; break;
                        } else if (firstLetter === letter) {
                            view.currentIndex = i; break;
                        }
                    }
                }
            }

            PathView {
                id: view
                anchors.fill: parent
                anchors.topMargin: 30
                clip: true
                interactive: true
                
                pathItemCount: 11
                snapMode: PathView.SnapToItem
                highlightRangeMode: PathView.StrictlyEnforceRange
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                dragMargin: 40

                model: appListModel
                delegate: AppIslandDelegate {}

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < appListModel.count) {
                        var currentApp = appListModel.get(currentIndex).app;
                        if (currentApp) {
                            var firstLetter = currentApp.name.substring(0, 1).toUpperCase();
                            if ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter)) {
                                alphabetScrubber.highlightedLetter = firstLetter;
                            } else {
                                alphabetScrubber.highlightedLetter = "#";
                            }
                        }
                    }
                }

                path: Path {
                    startX: -view.width * 0.2
                    startY: view.height / 2
                    
                    PathAttribute { name: "itemOpacity"; value: 0.1 }
                    PathLine { x: view.width * 0.5; y: view.height / 2 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }
                    PathLine { x: view.width * 1.2; y: view.height / 2 }
                    PathAttribute { name: "itemOpacity"; value: 0.1 }
                }

                ListModel { id: appListModel }

                function updateApps() {
                    let apps = DesktopEntries.applications.values.slice();
                    apps.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
                    
                    appListModel.clear();
                    for (let i = 0; i < apps.length; i++) {
                        appListModel.append({ "app": apps[i] });
                    }
                }

                Component.onCompleted: updateApps()
                
                Connections {
                    target: DesktopEntries.applications
                    function onValuesChanged() { view.updateApps() }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 8
                width: 32; height: 4
                radius: 2
                color: "white"
                opacity: 0.2
                visible: !root.searchVisible
            }
        }

        Rectangle {
            id: searchBar
            width: parent.width - 40
            height: FrameConfig.appIslandSearchBarHeight
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            radius: FrameConfig.appIslandSearchBarRadius
            color: FrameConfig.appIslandSearchBarColor
            opacity: 0
            visible: false
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "black"
                shadowOpacity: 0.3
                shadowBlur: 0.5
                shadowVerticalOffset: 2
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text { text: "󰍉"; color: "#666"; font.pixelSize: 16 }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#222"
                    font.pixelSize: FrameConfig.appIslandSearchInputFontSize
                    font.weight: Font.Medium
                    
                    Text {
                        text: "Search apps..."
                        color: "#999"
                        font.pixelSize: FrameConfig.appIslandSearchInputFontSize
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Connections {
                        target: root
                        function onSearchVisibleChanged() {
                            if (root.searchVisible) {
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                    onTextChanged: view.updateApps()
                }
            }
        }
    }
}
