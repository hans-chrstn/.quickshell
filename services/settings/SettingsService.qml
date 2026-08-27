pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property int selectedCategory: 0

    property alias revealDuration: data.revealDuration
    property alias resizeDuration: data.resizeDuration
    property alias contentRevealDuration: data.contentRevealDuration
    property alias attentionExpandDelay: data.attentionExpandDelay
    property alias moduleCloseDuration: data.moduleCloseDuration
    property alias expandDelay: data.expandDelay
    property alias hideDelay: data.hideDelay

    readonly property var categories: [
        { id: "motion", title: "Motion" },
        { id: "behavior", title: "Behavior" }
    ]

    function open(preferredScreenName) {
        closeTimer.stop()
        closing = false
        targetScreenName = ScreenService.resolve(preferredScreenName || "")
        selectedCategory = 0
        opened = true
    }

    function close() {
        if (!opened || closing)
            return
        opened = false
        closing = true
        closeTimer.restart()
    }

    function toggle(preferredScreenName) {
        opened ? close() : open(preferredScreenName)
    }

    function resetMotion() {
        revealDuration = 300
        resizeDuration = 520
        contentRevealDuration = 180
        attentionExpandDelay = 170
        moduleCloseDuration = 440
    }

    function resetBehavior() {
        expandDelay = 420
        hideDelay = 1200
    }

    Timer {
        id: closeTimer
        interval: root.moduleCloseDuration
        onTriggered: root.closing = false
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile
        path: Quickshell.statePath("settings.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: saveTimer.restart()
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
            else
                console.warn("Settings load failed:", error)
        }

        JsonAdapter {
            id: data
            property int revealDuration: 300
            property int resizeDuration: 520
            property int contentRevealDuration: 180
            property int attentionExpandDelay: 170
            property int moduleCloseDuration: 440
            property int expandDelay: 420
            property int hideDelay: 1200
        }
    }
}
