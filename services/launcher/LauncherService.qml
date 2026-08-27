pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.services.launcher
import qs.services

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property string query: ""
    property int selectedIndex: 0

    readonly property var providers: [DesktopAppProvider]
    readonly property var results: {
        if (!opened && !closing)
            return []

        const merged = []
        for (let i = 0; i < providers.length; ++i) {
            const provider = providers[i]
            if (!provider.enabled)
                continue
            const contribution = provider.search(query)
            for (let j = 0; j < contribution.length; ++j)
                merged.push(contribution[j])
        }

        merged.sort(function(a, b) {
            if (a.score !== b.score)
                return b.score - a.score
            if (a.providerId !== b.providerId)
                return a.providerId.localeCompare(b.providerId)
            return a.title.localeCompare(b.title)
        })
        return merged
    }

    onQueryChanged: selectedIndex = 0
    onResultsChanged: {
        if (results.length === 0)
            selectedIndex = -1
        else
            selectedIndex = Math.max(0, Math.min(selectedIndex,
                                                  results.length - 1))
    }

    function open(initialQuery, preferredScreenName) {
        closeTimer.stop()
        closing = false
        targetScreenName = ScreenService.resolve(preferredScreenName || "")
        query = initialQuery || ""
        selectedIndex = 0
        opened = true
    }

    function close() {
        if (!opened || closing)
            return
        opened = false
        closing = true
        closeTimer.restart()
    }

    function toggle() { opened ? close() : open("") }

    function moveSelection(delta) {
        if (results.length === 0) {
            selectedIndex = -1
            return
        }
        selectedIndex = Math.max(0, Math.min(results.length - 1,
                                             selectedIndex + delta))
    }

    function executeSelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return

        const result = results[selectedIndex]
        for (let i = 0; i < providers.length; ++i) {
            if (providers[i].providerId === result.providerId) {
                providers[i].execute(result)
                close()
                return
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Design.moduleCloseDuration
        onTriggered: {
            root.closing = false
            root.query = ""
            root.selectedIndex = 0
        }
    }
}
