import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.modules.island

Item {
    id: root
    
    property string filterText: ""
    property alias currentIndex: view.currentIndex
    
    onFilterTextChanged: updateApps()

    function updateApps() {
        let apps = DesktopEntries.applications.values.slice();
        let filter = root.filterText.toLowerCase();
        if (filter !== "") {
            apps = apps.filter(app => app.name.toLowerCase().includes(filter) || (app.description && app.description.toLowerCase().includes(filter)));
        }
        apps.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
        appListModel.clear();
        for (let i = 0; i < apps.length; i++) appListModel.append({ "app": apps[i] });
    }

    Component.onCompleted: updateApps()
    Connections { target: DesktopEntries.applications; function onValuesChanged() { root.updateApps() } }

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
    }
}
