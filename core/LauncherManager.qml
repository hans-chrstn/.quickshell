pragma Singleton

import QtQuick
import Quickshell
import qs.core

Singleton {
    id: root

    property bool active: false
    property string searchText: ""

    property ListModel appModel: ListModel { }
    readonly property alias model: root.appModel

    function toggle() {
        if (root.active) {
            root.close()
        } else {
            root.open()
        }
    }

    function open() {
        root.searchText = ""
        root.updateApps()
        root.active = true
    }

    function close() {
        root.active = false
    }

    function updateApps() {
        let apps = DesktopEntries.applications.values.slice()
        let filter = root.searchText.toLowerCase()

        if (filter !== "") {
            apps = apps.filter(app => {
                let nameMatch = app.name.toLowerCase().includes(filter)
                let descMatch = app.description && app.description.toLowerCase().includes(filter)
                return nameMatch || descMatch
            })
        }

        apps.sort((a, b) => {
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        })

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
