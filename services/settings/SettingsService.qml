pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.services.config

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property int selectedCategory: 0
    onSelectedCategoryChanged: clearPages()
    property var pageStack: []
    readonly property string currentPage: pageStack.length > 0
        ? String(pageStack[pageStack.length - 1]) : ""

    readonly property int revealDuration: ConfigService.revealDuration
    readonly property int resizeDuration: ConfigService.resizeDuration
    readonly property int contentRevealDuration: ConfigService.contentRevealDuration
    readonly property int attentionExpandDelay: ConfigService.attentionExpandDelay
    readonly property int moduleCloseDuration: ConfigService.moduleCloseDuration
    readonly property int expandDelay: ConfigService.expandDelay
    readonly property int hideDelay: ConfigService.hideDelay
    readonly property int islandWing: ConfigService.islandWing
    readonly property int islandCollapsedWidth: ConfigService.islandCollapsedWidth
    readonly property int islandWidthPercent: ConfigService.islandWidthPercent
    readonly property int islandHeightPercent: ConfigService.islandHeightPercent
    readonly property int islandBodyRadius: ConfigService.islandBodyRadius
    readonly property bool enableBlur: ConfigService.enableBlur

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
        clearPages()
        opened = true
    }

    function openCategory(categoryId, preferredScreenName) {
        const requested = String(categoryId || "").trim()

        for (let index = 0; index < categories.length; ++index) {
            if (categories[index].id === requested) {
                open(preferredScreenName)
                selectedCategory = index
                clearPages()
                return true
            }
        }

        for (let index = 0; index < categories.length; ++index) {
            const cat = categories[index]
            for (let subIndex = 0; subIndex < cat.subpages.length; ++subIndex) {
                if (cat.subpages[subIndex].id === requested) {
                    open(preferredScreenName)
                    selectedCategory = index
                    pageStack = [requested]
                    return true
                }
            }
        }
        return false
    }

    function close() {
        if (!opened || closing)
            return
        closing = true
        opened = false
        clearPages()
        closeTimer.restart()
    }

    function toggle(preferredScreenName) {
        opened ? close() : open(preferredScreenName)
    }

    function setSetting(key, value) {
        return ConfigService.setSetting(key, value)
    }

    function clearPages() {
        pageStack = []
    }

    function openPage(pageId) {
        const requested = String(pageId || "").trim()
        if (requested.length === 0 || requested === currentPage)
            return false
        pageStack = pageStack.concat([requested])
        return true
    }

    function back() {
        if (pageStack.length === 0)
            return false
        pageStack = pageStack.slice(0, pageStack.length - 1)
        return true
    }

    function openWallpaperDirectoryPicker(preferredScreenName) {
        openCategory("wallpaper", preferredScreenName)
        openPage("wallpaper_directory")
    }

    function openWallpaperOptions(preferredScreenName) {
        openCategory("wallpaper", preferredScreenName)
        openPage("wallpaper_options")
    }

    function resetMotion() {
        ConfigService.setSettings({
            revealDuration: 300,
            resizeDuration: 520,
            contentRevealDuration: 180,
            attentionExpandDelay: 170,
            moduleCloseDuration: 440
        })
    }

    function resetBehavior() {
        ConfigService.setSettings({ expandDelay: 420, hideDelay: 1200 })
    }

    function resetStyle() {
        ConfigService.setSettings({
            islandWing: 16,
            islandCollapsedWidth: 184,
            islandWidthPercent: 100,
            islandHeightPercent: 100,
            islandBodyRadius: 20,
            enableBlur: true
        })
    }

    Timer {
        id: closeTimer
        interval: root.moduleCloseDuration
        onTriggered: root.closing = false
    }

}
