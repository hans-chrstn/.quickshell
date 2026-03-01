import QtQuick
import Quickshell
import qs.core

Item {
    id: root

    property string filterText: ""
    property bool isIslandExpanded: false
    property alias currentIndex: view.currentIndex
    property var logic

    onFilterTextChanged: {
        if (logic) {
            logic.filterText = filterText
            logic.updateDebounce.restart()
        }
    }

    ApplicationScrubber {
        id: alphabetScrubber
        width: parent.width
        anchors.top: parent.top
        onLetterSelected: (letter) => {
            if (logic) {
                logic.selectLetter(letter, alphabetScrubber)
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
        model: logic ? logic.model : null

        delegate: AppIslandDelegate {
            isIslandExpanded: root.isIslandExpanded
        }

        onCurrentIndexChanged: {
            if (logic) {
                logic.handleCurrentIndexChanged(currentIndex, alphabetScrubber)
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

    Component.onCompleted: {
        if (logic) {
            logic.view = view
        }
    }
}
