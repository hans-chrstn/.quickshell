pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property color primaryColor: root.accentColor
    readonly property color highlightColor: root.accentColor
    readonly property color contentPrimaryColor: "#000000"
    readonly property color contentSecondaryColor: root.secondaryTextColor
    
    readonly property color backgroundPrimaryColor: root.backgroundColor
    readonly property color contentOnBackgroundColor: "#FFFFFF"
    
    property real lockBackgroundOpacity: 0.45
    property real lockBackgroundBlur: 1.0
    property int lockClockFontSize: 120
    property int lockDateFontSize: 16
    property real lockDateOpacity: 0.8
    property int lockDateLetterSpacing: 6
    property int lockContentSpacing: 50
    property real lockPasswordOpacity: 0.06
    property bool lockDynamicAccents: true
    property int lockParallaxIntensity: 20

    readonly property color surfacePrimaryColor: Qt.rgba(1, 1, 1, 0.05)
    readonly property color surfaceStrongColor: Qt.rgba(1, 1, 1, 0.1)
    readonly property color surfaceSubtleColor: Qt.rgba(1, 1, 1, 0.02)
    readonly property color surfaceContentColor: "#FFFFFF"
    
    readonly property color surfaceVariantColor: Qt.rgba(1, 1, 1, 0.08)
    readonly property color surfaceVariantContentColor: "#AAAAAA"
    readonly property color surfaceVariantStrongColor: Qt.rgba(1, 1, 1, 0.15)
    
    readonly property color outlinePrimaryColor: Qt.rgba(1, 1, 1, 0.1)
    readonly property color outlineStrongColor: Qt.rgba(1, 1, 1, 0.2)
    readonly property color outlineVariantColor: Qt.rgba(1, 1, 1, 0.05)
    
    readonly property color dangerPrimaryColor: root.dangerColor
    readonly property color dangerContentColor: "#FFFFFF"
    readonly property color dangerSurfaceColor: {
        let color = Qt.color(root.dangerColor);
        return Qt.rgba(color.r, color.g, color.b, 0.3);
    }
    
    readonly property color shadowPrimaryColor: "#000000"

    property int globalThickness: 16
    property int globalCornerRadius: 12
    property color backgroundColor: "#0D0D0F"
    property color accentColor: "#FFFFFF"
    property color dangerColor: "#FF5555"
    property color visualHighlightColor: "#FFFFFF"
    property real visualHighlightOpacity: 0.08
    property color secondaryTextColor: "#888888"

    property int animationDuration: 400
    property int animationEasing: Easing.OutQuart

    property real shadowOpacity: 0.4
    property int shadowBlurRadius: 15
    property int shadowVerticalOffset: 4

    property int dynamicIslandCornerRadius: 30
    property int dynamicIslandExpandedWidth: 420
    property int dynamicIslandExpandedHeight: 130
    property int dynamicIslandCollapsedWidth: 160
    property int islandCollapseDelay: 200
    
    property int appIslandExpandedWidth: 600
    property int appIslandExpandedHeight: 110
    property int appIslandDelegateWidth: 70
    property int appIslandDelegateHeight: 90
    property int appIslandIconSize: 40
    property real appIslandMinOpacity: 0.4

    property int appIslandSearchBarHeight: 36
    property int appIslandSearchBarRadius: 18
    property color appIslandSearchBarColor: "#FFFFFF"
    property int appIslandSearchInputFontSize: 14

    property int appIslandScrubberFontSize: 10
    property int appIslandScrubberSpacing: 4

    property int musicArtSize: 64
    property int musicArtRadius: 32
    property int musicHoleSize: 12
    property real musicArtShadowOpacity: 0.3
    property int musicControlSpacing: 24

    property bool isMusicArtVisible: true
    property bool isWeatherVisible: true

    property int notificationItemHeight: 60
    property int notificationIconSize: 36
    property int notificationSpacing: 4
    property real notificationOpacity: 0.04
    property real notificationHoverOpacity: 0.08

    property int cavaBarCount: 20
    property int cavaSpacing: 3
    property real cavaOpacity: 0.15
    property int cavaUpdateInterval: 100
    property real cavaSmoothing: 0.15

    property int weatherUpdateInterval: 300000
    property int musicRotationDuration: 8000
    
    property int osdPillWidth: 220
    property int osdPillHeight: 44
    property int osdPillRadius: 22
    property int osdHideDelay: 2000

    property int controlCenterTileSize: 44
    property int controlCenterTileRadius: 22
    property int controlCenterSliderWidth: 200
    property int controlCenterSliderHeight: 32

    property string timeFormat: "hh:mm"
    property string dateFormat: "dddd, MMMM d"

    property int roundedCornerShapeWidth: 20
    property int roundedCornerShapeRadius: 20
    property int pathViewTopMargin: 10
    property int pathViewBottomMargin: 5
    property int indicatorRowBottomMargin: 10
    property int indicatorRowSpacing: 6

    property bool isReady: false
    readonly property string configurationCachePath: Quickshell.cachePath("config.json")
    
    signal themeResetOccurred()
    
    property var settingsStructure: [
        {
            category: "Lockscreen",
            icon: "󰌾",
            items: [
                { type: "header", label: "Visuals" },
                { type: "switch", label: "Dynamic Accents", property: "lockDynamicAccents", default: true },
                { type: "slider", label: "Wallpaper Opacity", property: "lockBackgroundOpacity", default: 0.45, min: 0.0, max: 1.0, step: 0.05 },
                { type: "slider", label: "Blur Intensity", property: "lockBackgroundBlur", default: 1.0, min: 0.0, max: 2.0, step: 0.1 },
                { type: "slider", label: "Parallax Intensity", property: "lockParallaxIntensity", default: 20, min: 0, max: 100 },
                { type: "header", label: "Date & Time" },
                { type: "slider", label: "Clock Size", property: "lockClockFontSize", default: 120, min: 60, max: 240 },
                { type: "slider", label: "Date Size", property: "lockDateFontSize", default: 16, min: 10, max: 40 },
                { type: "slider", label: "Date Spacing", property: "lockDateLetterSpacing", default: 6, min: 0, max: 20 },
                { type: "header", label: "Layout" },
                { type: "slider", label: "Content Spacing", property: "lockContentSpacing", default: 50, min: 10, max: 150 },
                { type: "slider", label: "Password Opacity", property: "lockPasswordOpacity", default: 0.06, min: 0.0, max: 0.5, step: 0.01 }
            ]
        },
        {
            category: "Appearance",
            icon: "󰔉",
            items: [
                { type: "header", label: "Colors" },
                { type: "color", label: "Background", property: "backgroundColor", default: "#0D0D0F" },
                { type: "color", label: "Accent", property: "accentColor", default: "#FFFFFF" },
                { type: "color", label: "Danger", property: "dangerColor", default: "#FF5555" },
                { type: "color", label: "Highlight", property: "visualHighlightColor", default: "#FFFFFF" },
                { type: "color", label: "Secondary Text", property: "secondaryTextColor", default: "#888888" },
                { type: "header", label: "Geometry" },
                { type: "slider", label: "Thickness", property: "globalThickness", default: 16, min: 10, max: 100 },
                { type: "slider", label: "Corner Radius", property: "globalCornerRadius", default: 12, min: 0, max: 60 },
                { type: "header", label: "Shadows" },
                { type: "slider", label: "Opacity", property: "shadowOpacity", default: 0.4, min: 0.0, max: 1.0, step: 0.05 },
                { type: "slider", label: "Blur", property: "shadowBlurRadius", default: 15, min: 0, max: 50 },
                { type: "slider", label: "Offset Y", property: "shadowVerticalOffset", default: 4, min: 0, max: 20 },
                { type: "header", label: "Formats" },
                { type: "text", label: "Time Format", property: "timeFormat", default: "hh:mm" },
                { type: "text", label: "Date Format", property: "dateFormat", default: "dddd, MMMM d" }
            ]
        },
        {
            category: "Dynamic Island",
            icon: "󰘔",
            items: [
                { type: "header", label: "Dimensions" },
                { type: "slider", label: "Max Width", property: "dynamicIslandExpandedWidth", default: 420, min: 300, max: 800 },
                { type: "slider", label: "Max Height", property: "dynamicIslandExpandedHeight", default: 130, min: 80, max: 400 },
                { type: "slider", label: "Collapsed Width", property: "dynamicIslandCollapsedWidth", default: 160, min: 100, max: 300 },
                { type: "slider", label: "Corner Radius", property: "dynamicIslandCornerRadius", default: 30, min: 0, max: 60 }
            ]
        },
        {
            category: "Dock",
            icon: "󰇄",
            items: [
                { type: "header", label: "Layout" },
                { type: "slider", label: "Expanded Width", property: "appIslandExpandedWidth", default: 600, min: 400, max: 1200 },
                { type: "slider", label: "Expanded Height", property: "appIslandExpandedHeight", default: 110, min: 60, max: 200 },
                { type: "slider", label: "Icon Size", property: "appIslandIconSize", default: 40, min: 24, max: 80 },
                { type: "slider", label: "Min Opacity", property: "appIslandMinOpacity", default: 0.4, min: 0.0, max: 1.0, step: 0.05 },
                { type: "header", label: "Search Bar" },
                { type: "slider", label: "Height", property: "appIslandSearchBarHeight", default: 36, min: 20, max: 60 },
                { type: "slider", label: "Corner Radius", property: "appIslandSearchBarRadius", default: 18, min: 0, max: 30 },
                { type: "color", label: "Color", property: "appIslandSearchBarColor", default: "#FFFFFF" }
            ]
        },
        {
            category: "Music",
            icon: "󰎈",
            items: [
                { type: "header", label: "Album Art" },
                { type: "slider", label: "Size", property: "musicArtSize", default: 64, min: 30, max: 100 },
                { type: "slider", label: "Radius", property: "musicArtRadius", default: 32, min: 0, max: 50 },
                { type: "slider", label: "Hole Size", property: "musicHoleSize", default: 12, min: 0, max: 40 },
                { type: "slider", label: "Shadow Opacity", property: "musicArtShadowOpacity", default: 0.3, min: 0.0, max: 1.0, step: 0.05 },
                { type: "header", label: "Behavior" },
                { type: "slider", label: "Rotation Speed", property: "musicRotationDuration", default: 8000, min: 2000, max: 20000, step: 500 },
                { type: "slider", label: "Control Spacing", property: "musicControlSpacing", default: 24, min: 0, max: 50 }
            ]
        },
        {
            category: "OSD",
            icon: "󰕾",
            items: [
                { type: "header", label: "Dimensions" },
                { type: "slider", label: "Width", property: "osdPillWidth", default: 220, min: 150, max: 400 },
                { type: "slider", label: "Height", property: "osdPillHeight", default: 44, min: 30, max: 80 },
                { type: "slider", label: "Corner Radius", property: "osdPillRadius", default: 22, min: 0, max: 40 },
                { type: "header", label: "Behavior" },
                { type: "slider", label: "Hide Delay", property: "osdHideDelay", default: 2000, min: 500, max: 10000, step: 100 }
            ]
        },
        {
            category: "Notifications",
            icon: "󰂚",
            items: [
                { type: "header", label: "Appearance" },
                { type: "slider", label: "Item Height", property: "notificationItemHeight", default: 60, min: 40, max: 100 },
                { type: "slider", label: "Icon Size", property: "notificationIconSize", default: 36, min: 20, max: 60 },
                { type: "slider", label: "Spacing", property: "notificationSpacing", default: 4, min: 0, max: 20 },
                { type: "slider", label: "Opacity", property: "notificationOpacity", default: 0.04, min: 0.0, max: 1.0, step: 0.01 },
                { type: "slider", label: "Hover Opacity", property: "notificationHoverOpacity", default: 0.08, min: 0.0, max: 1.0, step: 0.01 }
            ]
        },
        {
            category: "Control Center",
            icon: "󰒓",
            items: [
                { type: "header", label: "Tiles" },
                { type: "slider", label: "Size", property: "controlCenterTileSize", default: 44, min: 30, max: 80 },
                { type: "slider", label: "Corner Radius", property: "controlCenterTileRadius", default: 22, min: 0, max: 40 },
                { type: "header", label: "Sliders" },
                { type: "slider", label: "Width", property: "controlCenterSliderWidth", default: 200, min: 100, max: 400 },
                { type: "slider", label: "Height", property: "controlCenterSliderHeight", default: 32, min: 20, max: 60 }
            ]
        },
        {
            category: "Advanced",
            icon: "󰒓",
            items: [
                { type: "header", label: "Visualizer" },
                { type: "slider", label: "Bar Count", property: "cavaBarCount", default: 20, min: 5, max: 50 },
                { type: "slider", label: "Bar Spacing", property: "cavaSpacing", default: 3, min: 0, max: 10 },
                { type: "slider", label: "Smoothing", property: "cavaSmoothing", default: 0.15, min: 0.05, max: 0.5, step: 0.01 },
                { type: "header", label: "Weather" },
                { type: "slider", label: "Update Interval", property: "weatherUpdateInterval", default: 300000, min: 60000, max: 3600000, step: 60000 },
                { type: "header", label: "Layout Internal" },
                { type: "slider", label: "PathView Top Margin", property: "pathViewTopMargin", default: 10, min: 0, max: 50 },
                { type: "slider", label: "PathView Bottom Margin", property: "pathViewBottomMargin", default: 5, min: 0, max: 50 }
            ]
        },
        {
            category: "Features",
            icon: "󰄔",
            items: [
                { type: "header", label: "Toggles" },
                { type: "switch", label: "Show Music Art", property: "isMusicArtVisible", default: true },
                { type: "switch", label: "Show Weather", property: "isWeatherVisible", default: true }
            ]
        }
    ]

    FileView {
        id: configurationCacheFile
        path: root.configurationCachePath
        blockLoading: true
        printErrors: true
        onLoaded: root.loadConfiguration()
        onInternalTextChanged: root.loadConfiguration()
    }

    function saveConfiguration() {
        let configurationData = {}
        for (let i = 0; i < root.settingsStructure.length; i++) {
            let categoryItems = root.settingsStructure[i].items
            for (let j = 0; j < categoryItems.length; j++) {
                if (categoryItems[j].property) {
                    configurationData[categoryItems[j].property] = root[categoryItems[j].property]
                }
            }
        }
        configurationCacheFile.setText(JSON.stringify(configurationData, null, 4))
    }

    function loadConfiguration() {
        if (!root.isReady) return
        let configurationContent = configurationCacheFile.text()
        if (configurationContent) {
            try {
                let configurationData = JSON.parse(configurationContent)
                for (let settingKey in configurationData) {
                    if (root[settingKey] !== undefined) {
                        root[settingKey] = configurationData[settingKey]
                    }
                }
            } catch (error) {}
        }
    }

    function resetToDefaults() {
        for (let i = 0; i < root.settingsStructure.length; i++) {
            let categoryItems = root.settingsStructure[i].items
            for (let j = 0; j < categoryItems.length; j++) {
                if (categoryItems[j].property && categoryItems[j].default !== undefined) {
                    root[categoryItems[j].property] = categoryItems[j].default
                }
            }
        }
        root.saveConfiguration()
        root.themeResetOccurred()
    }

    Component.onCompleted: {
        root.isReady = true
        root.loadConfiguration()
    }
}
