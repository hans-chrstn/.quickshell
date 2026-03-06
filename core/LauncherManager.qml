pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.shared

Singleton {
    id: root

    property bool active: false
    property bool isClosing: false
    property string searchText: ""

    property ListModel appModel: ListModel { }
    readonly property alias model: root.appModel

    function toggle() {
        if (root.active && !root.isClosing) {
            root.close()
        } else {
            root.open()
        }
    }

    function open() {
        root.isClosing = false
        root.searchText = ""
        root.updateApps()
        root.active = true
    }

    function close() {
        if (!root.active || root.isClosing) return
        root.isClosing = true
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 350
        onTriggered: {
            root.active = false
            root.isClosing = false
            root.searchText = ""
        }
    }

    function updateApps() {
        let apps = DesktopEntries.applications.values.slice()
        let filter = root.searchText.toLowerCase()

        if (filter !== "") {
            let scoredApps = []
            for (let i = 0; i < apps.length; i++) {
                let app = apps[i]
                
                let nameScore = FuzzySearch.score(filter, app.name)
                let descScore = app.description ? FuzzySearch.score(filter, app.description) * 0.4 : 0
                let totalScore = Math.max(nameScore, descScore)
                
                if (totalScore > 0) {
                    scoredApps.push({
                        "app": app,
                        "score": totalScore
                    })
                }
            }

            scoredApps.sort((a, b) => {
                if (Math.abs(b.score - a.score) > 0.001) {
                    return b.score - a.score
                }
                return a.app.name.toLowerCase().localeCompare(b.app.name.toLowerCase())
            })

            apps = []
            for (let i = 0; i < scoredApps.length; i++) {
                apps.push(scoredApps[i].app)
            }
        } else {
            apps.sort((a, b) => {
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            })
        }

        appModel.clear()
        for (let i = 0; i < apps.length; i++) {
            appModel.append({ "app": apps[i] })
        }
    }

    onSearchTextChanged: {
        updateTimer.restart()
    }

    Timer {
        id: updateTimer
        interval: 250
        onTriggered: {
            root.updateApps()
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            updateTimer.restart()
        }
    }

    Component.onCompleted: {
        root.updateApps()
    }
}
