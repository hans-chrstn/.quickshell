import QtQuick
import Quickshell
import qs.core

Item {
    id: root

    property bool isIslandExpanded: false
    property alias currentIndex: view.currentIndex

    ApplicationScrubber {
        id: alphabetScrubber
        width: parent.width
        anchors.top: parent.top
        onLetterSelected: (letter) => {
            for (let i = 0; i < LauncherManager.model.count; i++) {
                let item = LauncherManager.model.get(i)
                if (item && item.app) {
                    let firstLetter = item.app.name.substring(0, 1).toUpperCase()
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
    }

    PathView {
        id: view
        anchors.fill: parent
        anchors.topMargin: 45
        anchors.bottomMargin: 10
        clip: false
        interactive: true
        pathItemCount: 11
        snapMode: PathView.SnapToItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        dragMargin: 40
        model: LauncherManager.model

        delegate: AppIslandDelegate {
            isIslandExpanded: root.isIslandExpanded
        }

        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < LauncherManager.model.count) {
                let item = LauncherManager.model.get(currentIndex)
                if (item && item.app) {
                    let firstLetter = item.app.name.substring(0, 1).toUpperCase()
                    alphabetScrubber.activeLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter) ? firstLetter : "#"
                }
            }
        }

        path: Path {
            startX: -view.width * 0.2
            startY: view.height / 2
            PathAttribute {
                name: "itemOpacity"
                value: ThemeManager.appIslandMinOpacity
            }
            PathLine {
                x: view.width * 0.5
                y: view.height / 2
            }
            PathAttribute {
                name: "itemOpacity"
                value: 1.0
            }
            PathLine {
                x: view.width * 1.2
                y: view.height / 2
            }
            PathAttribute {
                name: "itemOpacity"
                value: ThemeManager.appIslandMinOpacity
            }
        }
    }
}
