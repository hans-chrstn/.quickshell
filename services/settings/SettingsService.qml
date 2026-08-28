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
    onSelectedCategoryChanged: currentSubpage = ""
    property string currentSubpage: ""

    property alias revealDuration: data.revealDuration
    property alias resizeDuration: data.resizeDuration
    property alias contentRevealDuration: data.contentRevealDuration
    property alias attentionExpandDelay: data.attentionExpandDelay
    property alias moduleCloseDuration: data.moduleCloseDuration
    property alias expandDelay: data.expandDelay
    property alias hideDelay: data.hideDelay

    property alias islandWing: data.islandWing
    property alias islandCollapsedWidth: data.islandCollapsedWidth
    property alias islandWidthPercent: data.islandWidthPercent
    property alias islandHeightPercent: data.islandHeightPercent
    property alias islandBodyRadius: data.islandBodyRadius
    property alias enableBlur: data.enableBlur

    readonly property var categories: [
        {
            id: "personalization",
            title: "Personalization",
            subpages: [
                { id: "wallpaper", title: "Wallpaper", desc: "Select background images" },
                { id: "island_style", title: "Island Style", desc: "Customize dimensions, radius, and blur" }
            ]
        },
        {
            id: "interaction",
            title: "Interaction",
            subpages: [
                { id: "motion", title: "Motion", desc: "Configure animation durations and curves" },
                { id: "behavior", title: "Behavior", desc: "Adjust hover intent and auto-hide delays" }
            ]
        }
    ]

    function open(preferredScreenName) {
        closeTimer.stop()
        closing = false
        targetScreenName = ScreenService.resolve(preferredScreenName || "")
        selectedCategory = 0
        currentSubpage = ""
        opened = true
    }

    function openCategory(categoryId, preferredScreenName) {
        const requested = String(categoryId || "").trim()

        for (let index = 0; index < categories.length; ++index) {
            if (categories[index].id === requested) {
                open(preferredScreenName)
                selectedCategory = index
                currentSubpage = ""
                return true
            }
        }

        for (let index = 0; index < categories.length; ++index) {
            const cat = categories[index]
            for (let subIndex = 0; subIndex < cat.subpages.length; ++subIndex) {
                if (cat.subpages[subIndex].id === requested) {
                    open(preferredScreenName)
                    selectedCategory = index
                    currentSubpage = requested
                    return true
                }
            }
        }
        return false
    }

    function close() {
        if (!opened || closing)
            return
        opened = false
        closing = true
        currentSubpage = ""
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

    function resetStyle() {
        islandWing = 16
        islandCollapsedWidth = 184
        islandWidthPercent = 100
        islandHeightPercent = 100
        islandBodyRadius = 20
        enableBlur = true
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

            property int islandWing: 16
            property int islandCollapsedWidth: 184
            property int islandWidthPercent: 100
            property int islandHeightPercent: 100
            property int islandBodyRadius: 20
            property bool enableBlur: true
        }
    }
}
