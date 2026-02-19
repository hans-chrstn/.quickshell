import QtQuick
import QtQuick.Layouts
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
    property alias isInteracting: hoverHandler.hovered

    states: [
        State {
            name: "search"
            when: root.searchVisible
            PropertyChanges { target: root; height: FrameConfig.appIslandExpandedHeight + searchBar.height + FrameConfig.appIslandSearchBarTopMargin }
            PropertyChanges { target: searchBar; visible: true; opacity: 1 }
        },
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: root; width: FrameConfig.appIslandExpandedWidth; height: FrameConfig.appIslandExpandedHeight }
            PropertyChanges { target: islandContentArea; opacity: 1 }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandCollapsedWidth; height: root.barHeight }
            PropertyChanges { target: islandContentArea; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            from: "collapsed"; to: "expanded"
            NumberAnimation {
                properties: "width,height"
                duration: FrameConfig.animDuration
                easing.type: Easing.OutExpo
            }
            SequentialAnimation {
                PauseAnimation { duration: FrameConfig.animDuration * 0.5 }
                NumberAnimation {
                    target: islandContentArea
                    property: "opacity"
                    duration: FrameConfig.animDuration * 0.5
                }
            }
        },
        Transition {
            from: "expanded"; to: "collapsed"
            NumberAnimation {
                properties: "width,height"
                duration: FrameConfig.animDuration
                easing.type: Easing.InExpo
            }
            NumberAnimation {
                target: islandContentArea
                property: "opacity"
                duration: FrameConfig.animDuration * 0.5
            }
        }
    ]

    Item {
        id: islandContainer
        anchors.fill: parent

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: root.expanded = hovered
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            property real initialY: 0
            onPressed: (mouse) => initialY = mouse.y
            onPositionChanged: (mouse) => {
                if (initialY - mouse.y > FrameConfig.appIslandDragThreshold) {
                    root.searchVisible = true
                }
            }
            onReleased: (mouse) => {
                if (initialY - mouse.y < -FrameConfig.appIslandDragThreshold) {
                    root.searchVisible = false
                }
            }
        }

        RoundedCornerShape {
            anchors.right: islandRect.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth
            height: Math.min(FrameConfig.roundedCornerShapeWidth, Math.max(0, root.height - root.barHeight))
            isLeft: true
            isBottom: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            visible: root.height > (root.barHeight + 2)
        }

        RoundedCornerShape {
            anchors.left: islandRect.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth
            height: Math.min(FrameConfig.roundedCornerShapeWidth, Math.max(0, root.height - root.barHeight))
            isLeft: false
            isBottom: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            visible: root.height > (root.barHeight + 2)
        }

        ClippingRectangle {
            id: islandRect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.barColor

            states: [
                State {
                    name: "expanded"; when: root.expanded
                    PropertyChanges {
                        target: islandRect
                        topLeftRadius: FrameConfig.dynamicIslandCornerRadius
                        topRightRadius: FrameConfig.dynamicIslandCornerRadius
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }
                },
                State {
                    name: "collapsed"; when: !root.expanded
                    PropertyChanges {
                        target: islandRect
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "collapsed"; to: "expanded"
                    NumberAnimation { properties: "topLeftRadius,topRightRadius"; duration: FrameConfig.animDuration; easing.type: Easing.OutExpo }
                },
                Transition {
                    from: "expanded"; to: "collapsed"
                    NumberAnimation { properties: "topLeftRadius,topRightRadius"; duration: FrameConfig.animDuration; easing.type: Easing.InExpo }
                }
            ]

            Item {
                id: islandContentArea
                anchors.fill: parent
                opacity: 0
                clip: true

                AlphabetScrubber {
                    id: alphabetScrubber
                    width: parent.width
                    anchors.top: parent.top
                    onLetterClicked: (letter) => {
                        for (var i = 0; i < appListModel.count; i++) {
                            var app = appListModel.get(i).app
                            var firstLetter = app.name.substring(0, 1).toUpperCase()
                            if (letter === "#" && !"ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter)) {
                                view.currentIndex = i
                                break
                            } else if (firstLetter === letter) {
                                view.currentIndex = i
                                break
                            }
                        }
                    }
                }

                PathView {
                    id: view
                    anchors.fill: parent
                    anchors.topMargin: 30
                    clip: true

                    model: appListModel
                    delegate: AppIslandDelegate { app: model.app }

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < appListModel.count) {
                            var currentApp = appListModel.get(currentIndex).app
                            var firstLetter = currentApp.name.substring(0, 1).toUpperCase()
                            if ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter)) {
                                alphabetScrubber.highlightedLetter = firstLetter
                            } else {
                                alphabetScrubber.highlightedLetter = "#"
                            }
                        }
                    }

                    path: Path {
                        startX: 0
                        startY: view.height / 2
                        PathLine { x: view.width; y: view.height / 2 }
                    }
                    
                    pathItemCount: 7
                    
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    snapMode: PathView.SnapToItem

                    ListModel { id: appListModel }

                    ScriptModel {
                        id: scriptModel
                        values: {
                            var apps = DesktopEntries.applications.values.slice()

                            if (FrameConfig.appIslandSortMode === "alphabetical") {
                                apps.sort(function(a, b) {
                                    if (a.name.toLowerCase() < b.name.toLowerCase()) return -1
                                    if (a.name.toLowerCase() > b.name.toLowerCase()) return 1
                                    return 0
                                })
                            }

                            if (searchInput.text === "") {
                                return apps
                            } else {
                                return apps.filter(function(app) {
                                    return app.name.toLowerCase().includes(searchInput.text.toLowerCase()) ||
                                           (app.keywords && app.keywords.join(" ").toLowerCase().includes(searchInput.text.toLowerCase()))
                                })
                            }
                        }
                        onValuesChanged: {
                            appListModel.clear()
                            var apps = scriptModel.values
                            if (apps.length > 0) {
                                for (var i = 0; i < apps.length; i++) {
                                    var app = apps[i]
                                    if (app) appListModel.append({ "app": app })
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: searchBar
                width: parent.width - (FrameConfig.appIslandSearchBarHorizontalMargin * 2)
                height: FrameConfig.appIslandSearchBarHeight
                anchors.top: parent.top
                anchors.topMargin: FrameConfig.appIslandSearchBarTopMargin
                anchors.horizontalCenter: parent.horizontalCenter
                radius: FrameConfig.appIslandSearchBarRadius
                color: FrameConfig.appIslandSearchBarColor
                visible: false
                opacity: 0

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: FrameConfig.appIslandSearchInputHorizontalMargin
                    anchors.rightMargin: FrameConfig.appIslandSearchInputHorizontalMargin
                    verticalAlignment: TextInput.AlignVCenter
                    color: "white"
                    font.pixelSize: FrameConfig.appIslandSearchInputFontSize

                    Connections {
                        target: root
                        function onSearchVisibleChanged() {
                            if (root.searchVisible) {
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: FrameConfig.appIslandArrowIndicatorTopMargin
                text: FrameConfig.appIslandArrowIndicatorText
                color: "white"
                font.pixelSize: FrameConfig.appIslandArrowIndicatorSize
                visible: root.expanded && !root.searchVisible
            }
        }
    }
}