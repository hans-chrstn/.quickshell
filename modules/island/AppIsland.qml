import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.modules.island

BaseIsland {
    id: root

    expandedWidth: FrameConfig.appIslandExpandedWidth
    expandedHeight: root.searchVisible ? (FrameConfig.appIslandExpandedHeight + searchBar.height + 10) : FrameConfig.appIslandExpandedHeight
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
    property alias isInteracting: root.mouseHovered
    
    onMouseHoveredChanged: root.expanded = mouseHovered

    Item {
        anchors.fill: parent

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
            id: view; anchors.fill: parent; anchors.topMargin: 30; anchors.bottomMargin: 10
            clip: true; interactive: true
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
                PathAttribute { name: "itemOpacity"; value: 0.1 }
                PathLine { x: view.width * 0.5; y: view.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 1.0 }
                PathLine { x: view.width * 1.2; y: view.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 0.1 }
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

        Rectangle {
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 8
            width: 32; height: 4; radius: 2; color: "white"; opacity: 0.2; visible: !root.searchVisible
        }
    }

    Rectangle {
        id: searchBar
        width: parent.width - 40; height: FrameConfig.appIslandSearchBarHeight
        anchors.top: parent.top; anchors.topMargin: 12; anchors.horizontalCenter: parent.horizontalCenter
        radius: FrameConfig.appIslandSearchBarRadius; color: FrameConfig.appIslandSearchBarColor
        opacity: root.searchVisible ? 1 : 0; visible: opacity > 0.01
        
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
            Text { text: "󰍉"; color: "#666"; font.pixelSize: 16 }
            TextInput {
                id: searchInput
                Layout.fillWidth: true; verticalAlignment: TextInput.AlignVCenter; color: "#222"
                font.pixelSize: FrameConfig.appIslandSearchInputFontSize; font.weight: Font.Medium
                Text {
                    text: "Search apps..."; color: "#999"; font.pixelSize: FrameConfig.appIslandSearchInputFontSize
                    visible: !searchInput.text && !searchInput.activeFocus
                }
                Connections { target: root; function onSearchVisibleChanged() { if (root.searchVisible) searchInput.forceActiveFocus() } }
                onTextChanged: view.updateApps()
            }
        }
    }
}
