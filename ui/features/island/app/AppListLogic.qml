import QtQuick
import Quickshell
import qs.core

QtObject {
    id: root

    property string filterText: ""
    property var view

    property ListModel appListModel: ListModel { }
    readonly property alias model: root.appListModel

    function updateApps() {
        let apps = DesktopEntries.applications.values.slice()
        let filter = root.filterText.toLowerCase()

        if (filter !== "") {
            apps = apps.filter(app => {
                return app.name.toLowerCase().includes(filter) || (app.description && app.description.toLowerCase().includes(filter))
            })
        }

        apps.sort((a, b) => {
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        })

        appListModel.clear()
        for (let i = 0; i < apps.length; i++) {
            appListModel.append({
                "app": apps[i]
            })
        }
    }

    function selectLetter(letter, alphabetScrubber) {
        for (let i = 0; i < appListModel.count; i++) {
            let item = appListModel.get(i)
            if (!item || !item.app) {
                continue
            }

            let app = item.app
            let firstLetter = app.name.substring(0, 1).toUpperCase()

            if (letter === "#" && !"ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter)) {
                if (view) {
                    view.currentIndex = i
                }
                break
            } else if (firstLetter === letter) {
                if (view) {
                    view.currentIndex = i
                }
                break
            }
        }
    }

    function handleCurrentIndexChanged(currentIndex, alphabetScrubber) {
        if (currentIndex >= 0 && currentIndex < appListModel.count) {
            let item = appListModel.get(currentIndex)
            if (item && item.app) {
                let currentApp = item.app
                let firstLetter = currentApp.name.substring(0, 1).toUpperCase()
                if (alphabetScrubber) {
                    alphabetScrubber.activeLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(firstLetter) ? firstLetter : "#"
                }
            }
        }
    }

    property var updateDebounce: Timer {
        interval: 150
        onTriggered: {
            root.updateApps()
        }
    }

    property var connections: Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.updateApps()
        }
    }

    Component.onCompleted: {
        root.updateApps()
    }
}
