pragma Singleton
import QtQuick

QtObject {
    readonly property int thickness: 16
    readonly property int cornerRadius: 12
    readonly property color color: "#0D0D0F"
    readonly property color accentColor: "#FFFFFF"
    readonly property color dangerColor: "#FF5555"
    readonly property color highlightColor: "#FFFFFF"
    readonly property real highlightOpacity: 0.08
    readonly property color secondaryTextColor: "#888888"

    readonly property int animDuration: 450
    readonly property int animEasing: Easing.OutQuart

    readonly property real shadowOpacity: 0.4
    readonly property int shadowBlur: 15
    readonly property int shadowVerticalOffset: 4

    property int dynamicIslandCornerRadius: 30
    property int dynamicIslandExpandedWidth: 420
    property int dynamicIslandExpandedHeight: 130
    property int dynamicIslandCollapsedWidth: 120
    property int collapseTimerDelay: 200
    
    property int appIslandExpandedWidth: 600
    property int appIslandExpandedHeight: 130
    property string appIslandSortMode: "alphabetical"
    property int appIslandIconSize: 48
    property int appIslandHighlightAnimDuration: 150
    property real appIslandMinOpacity: 0.5
    property real appIslandMinScale: 0.8

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

    property int notifItemHeight: 60
    property int notifIconSize: 36
    property int notifSpacing: 4
    property real notifOpacity: 0.04
    property real notifHoverOpacity: 0.08

    property int cavaBarCount: 32
    property int cavaSpacing: 2
    property real cavaOpacity: 0.15
    property int cavaUpdateInterval: 100

    property int roundedCornerShapeWidth: 20
    property int roundedCornerShapeRadius: 20
    property int pathViewTopMargin: 10
    property int pathViewBottomMargin: 5
    property int indicatorRowBottomMargin: 10
    property int indicatorRowSpacing: 6
}
