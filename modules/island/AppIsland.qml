import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.modules.island

BaseIsland {
    id: appIslandRoot

    expandedWidth: FrameConfig.appIslandExpandedWidth
    expandedHeight: appIslandRoot.searchVisible ? (FrameConfig.appIslandExpandedHeight + FrameConfig.appIslandSearchBarHeight + 10) : FrameConfig.appIslandExpandedHeight
    collapsedWidth: FrameConfig.dynamicIslandCollapsedWidth
    
    isTop: false
    isBottom: true
    isCorner: false

    f1Rotation: 90
    f1X: -radius + 1
    f1Y: height - barHeight - radius

    f2Rotation: 180
    f2X: width - 1
    f2Y: height - barHeight - radius

    property bool searchVisible: false
    property alias isInteracting: appIslandRoot.mouseHovered
    property int activeMenus: 0
    
    onMouseHoveredChanged: {
        if (mouseHovered) {
            collapseTimer.stop()
            appIslandRoot.expanded = true
        } else if (!searchVisible && activeMenus === 0) {
            collapseTimer.restart()
        }
    }
    
    onActiveMenusChanged: {
        if (activeMenus > 0) {
            collapseTimer.stop()
            appIslandRoot.expanded = true
        } else if (!mouseHovered && !searchVisible) {
            collapseTimer.restart()
        }
    }
    
    onExpandedChanged: if (!expanded) searchVisible = false 

    Timer { id: collapseTimer; interval: 300; onTriggered: appIslandRoot.expanded = false }

    Behavior on height {
        enabled: appIslandRoot.expanded
        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }
        
        Item {
            id: contentContainer
            anchors.fill: parent
            
            anchors.topMargin: appIslandRoot.searchVisible ? (FrameConfig.appIslandSearchBarHeight + 8) : 0
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

            AlphabetScrubber {
                id: alphabetScrubber
                width: parent.width; anchors.top: parent.top
                onLetterClicked: (letter) => {
                    for (var i = 0; i < appListModel.count; i++) {
                        var item = appListModel.get(i);
                        if (!item || !item.app) continue;
                        var app = item.app;
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
                id: view; anchors.fill: parent; 
                anchors.topMargin: 45; anchors.bottomMargin: 10
                clip: false
                interactive: true
                pathItemCount: 11; snapMode: PathView.SnapToItem; highlightRangeMode: PathView.StrictlyEnforceRange
                preferredHighlightBegin: 0.5; preferredHighlightEnd: 0.5; dragMargin: 40
                model: appListModel; delegate: AppIslandDelegate {}

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < appListModel.count) {
                        var currentApp = appListModel.get(currentIndex).app;
                        if (currentApp) {
                            var firstLetter = currentApp.name.substring(0, 1).toUpperCase();
                            alphabetScrubber.highlightedLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter) ? firstLetter : "#";
                        }
                    }
                }

                path: Path {
                    startX: -view.width * 0.2; startY: view.height / 2
                    PathAttribute { name: "itemOpacity"; value: FrameConfig.appIslandMinOpacity }
                    PathLine { x: view.width * 0.5; y: view.height / 2 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }
                    PathLine { x: view.width * 1.2; y: view.height / 2 }
                    PathAttribute { name: "itemOpacity"; value: FrameConfig.appIslandMinOpacity }
                }

                ListModel { id: appListModel }

                function updateApps() {
                    let apps = DesktopEntries.applications.values.slice();
                    let filter = searchInput.text.toLowerCase();
                    if (filter !== "") {
                        apps = apps.filter(app => app.name.toLowerCase().includes(filter) || (app.description && app.description.toLowerCase().includes(filter)));
                    }
                    apps.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
                    appListModel.clear();
                    for (let i = 0; i < apps.length; i++) appListModel.append({ "app": apps[i] });
                }

                Component.onCompleted: updateApps()
                Connections { target: DesktopEntries.applications; function onValuesChanged() { view.updateApps() } }
            }
        }

        Rectangle {
            id: searchBar
            
            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => mouse.accepted = true
            }
            
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: appIslandRoot.searchVisible ? 12 : 6
            
            width: appIslandRoot.searchVisible ? (parent.width - 40) : 24
            height: appIslandRoot.searchVisible ? FrameConfig.appIslandSearchBarHeight : 4
            radius: appIslandRoot.searchVisible ? FrameConfig.appIslandSearchBarRadius : 2
            
            color: appIslandRoot.searchVisible ? Qt.rgba(0.1, 0.1, 0.12, 0.95) : "white"
            opacity: appIslandRoot.searchVisible ? 1.0 : 0.2
            
            border.color: "white"
            border.width: appIslandRoot.searchVisible ? 1 : 0
            visible: true
            
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on radius { NumberAnimation { duration: 400 } }
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Behavior on border.width { NumberAnimation { duration: 400 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 10
                opacity: appIslandRoot.searchVisible ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                Text { 
                    text: "󰍉"
                    color: "white"
                    opacity: 0.5
                    font.pixelSize: 18 
                }
                
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true; verticalAlignment: TextInput.AlignVCenter
                    color: FrameConfig.appIslandSearchBarColor
                    font.pixelSize: FrameConfig.appIslandSearchInputFontSize
                    font.weight: Font.Medium
                    selectionColor: FrameConfig.accentColor
                    
                    Text {
                        text: "Search applications..."
                        color: "white"
                        opacity: 0.3
                        font.pixelSize: 14
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                    
                    onTextChanged: view.updateApps()
                    
                    Connections {
                        target: appIslandRoot
                        function onSearchVisibleChanged() {
                            if (!appIslandRoot.searchVisible) {
                                searchInput.text = ""
                            }
                        }
                    }
                }
                
                Text { 
                    text: "󰅖"
                    color: "white"
                    opacity: 0.4
                    font.pixelSize: 16 
                    
                    TapHandler { 
                        onTapped: {
                            appIslandRoot.searchVisible = false
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    
                    scale: shhClose.hovered ? 1.2 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    HoverHandler { id: shhClose }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !appIslandRoot.searchVisible
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    appIslandRoot.searchVisible = true
                }
            }
        }
    }
}
