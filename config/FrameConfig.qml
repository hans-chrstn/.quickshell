pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int thickness: 16
    property int cornerRadius: 12
    property color color: "#0D0D0F"
    property color accentColor: "#FFFFFF"
    property color dangerColor: "#FF5555"
    property color highlightColor: "#FFFFFF"
    property real highlightOpacity: 0.08
    property color secondaryTextColor: "#888888"

    property int animDuration: 300
    property int animEasing: Easing.OutQuart

    property real shadowOpacity: 0.4
    property int shadowBlur: 15
    property int shadowVerticalOffset: 4

    property int dynamicIslandCornerRadius: 30
    property int dynamicIslandExpandedWidth: 420
    property int dynamicIslandExpandedHeight: 130
    property int dynamicIslandCollapsedWidth: 160
    property int collapseTimerDelay: 200
    
    property int appIslandExpandedWidth: 600
    property int appIslandExpandedHeight: 110
    property int appIslandDelegateWidth: 70
    property int appIslandDelegateHeight: 90
    property int appIslandIconSize: 40
    property real appIslandMinOpacity: 0.4
    property string appIslandSortMode: "alphabetical"

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

    property bool showMusicArt: true
    property bool blurBackground: true
    property bool showWeather: true

    property int notifItemHeight: 60
    property int notifIconSize: 36
    property int notifSpacing: 4
    property real notifOpacity: 0.04
    property real notifHoverOpacity: 0.08

    property int cavaBarCount: 20
    property int cavaSpacing: 3
    property real cavaOpacity: 0.15
    property int cavaUpdateInterval: 100

    property int roundedCornerShapeWidth: 20
    property int roundedCornerShapeRadius: 20
    property int pathViewTopMargin: 10
    property int pathViewBottomMargin: 5
    property int indicatorRowBottomMargin: 10
    property int indicatorRowSpacing: 6

    property bool ready: false
    readonly property string cachePath: Quickshell.shellPath("cache/config_cache.json")
    
    signal resetOccurred()
    
    property var settingsStructure: [
        {
            category: "Appearance",
            icon: "󰔉",
            items: [
                { type: "header", label: "Colors" },
                { type: "color", label: "Background", property: "color", default: "#0D0D0F" },
                { type: "color", label: "Accent", property: "accentColor", default: "#FFFFFF" },
                { type: "color", label: "Danger", property: "dangerColor", default: "#FF5555" },
                { type: "color", label: "Highlight", property: "highlightColor", default: "#FFFFFF" },
                { type: "color", label: "Secondary Text", property: "secondaryTextColor", default: "#888888" },
                { type: "header", label: "Geometry" },
                { type: "slider", label: "Thickness", property: "thickness", default: 16, min: 10, max: 100 },
                { type: "slider", label: "Corner Radius", property: "cornerRadius", default: 12, min: 0, max: 60 },
                { type: "header", label: "Shadows" },
                { type: "slider", label: "Opacity", property: "shadowOpacity", default: 0.4, min: 0.0, max: 1.0, step: 0.05 },
                { type: "slider", label: "Blur", property: "shadowBlur", default: 15, min: 0, max: 50 },
                { type: "slider", label: "Offset Y", property: "shadowVerticalOffset", default: 4, min: 0, max: 20 }
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
                { type: "header", label: "Controls" },
                { type: "slider", label: "Spacing", property: "musicControlSpacing", default: 24, min: 0, max: 50 }
            ]
        },
        {
            category: "Notifications",
            icon: "󰂚",
            items: [
                { type: "header", label: "Appearance" },
                { type: "slider", label: "Item Height", property: "notifItemHeight", default: 60, min: 40, max: 100 },
                { type: "slider", label: "Icon Size", property: "notifIconSize", default: 36, min: 20, max: 60 },
                { type: "slider", label: "Spacing", property: "notifSpacing", default: 4, min: 0, max: 20 },
                { type: "slider", label: "Opacity", property: "notifOpacity", default: 0.04, min: 0.0, max: 1.0, step: 0.01 },
                { type: "slider", label: "Hover Opacity", property: "notifHoverOpacity", default: 0.08, min: 0.0, max: 1.0, step: 0.01 }
            ]
        },
        {
            category: "Visualizer",
            icon: "󰓃",
            items: [
                { type: "header", label: "Cava" },
                { type: "slider", label: "Bar Count", property: "cavaBarCount", default: 20, min: 5, max: 50 },
                { type: "slider", label: "Spacing", property: "cavaSpacing", default: 3, min: 0, max: 10 },
                { type: "slider", label: "Opacity", property: "cavaOpacity", default: 0.15, min: 0.0, max: 1.0, step: 0.05 }
            ]
        },
        {
            category: "Features",
            icon: "󰄔",
            items: [
                { type: "header", label: "Toggles" },
                { type: "switch", label: "Show Music Art", property: "showMusicArt", default: true },
                { type: "switch", label: "Blur Background", property: "blurBackground", default: true },
                { type: "switch", label: "Show Weather", property: "showWeather", default: true }
            ]
        }
    ]

    FileView {
        id: cacheFile
        path: root.cachePath
        blockLoading: true
        printErrors: true
        
        onLoaded: {
            root.load()
        }
        
        onInternalTextChanged: {
             root.load()
        }
    }

    function save(): void {
        let data = {}
        for (let i = 0; i < settingsStructure.length; i++) {
            let items = settingsStructure[i].items
            for (let j = 0; j < items.length; j++) {
                if (items[j].property) {
                    data[items[j].property] = root[items[j].property]
                }
            }
        }
        cacheFile.setText(JSON.stringify(data, null, 4))
    }

    function load(): void {
        if (!root.ready) {
            return
        }
        
        let content = cacheFile.text()
        if (content) {
            try {
                let data = JSON.parse(content)
                for (let key in data) {
                    if (root[key] !== undefined) {
                        root[key] = data[key]
                    }
                }
                console.log("FrameConfig: Config loaded.")
            } catch (e) {
                console.log("FrameConfig: Failed to parse config cache: " + e)
            }
        } else {
            console.log("FrameConfig: Cache is empty.")
        }
    }

    function reset(): void {
        for (let i = 0; i < settingsStructure.length; i++) {
            let items = settingsStructure[i].items
            for (let j = 0; j < items.length; j++) {
                if (items[j].property && items[j].default !== undefined) {
                    root[items[j].property] = items[j].default
                }
            }
        }
        root.save()
        root.resetOccurred()
    }

    Component.onCompleted: {
        root.ready = true
        root.load()
    }
}
