pragma Singleton
import QtQuick

QtObject {
    readonly property int thickness: 16
    readonly property int cornerRadius: 12
    readonly property color color: "#0D0D0F"
    readonly property color accentColor: "#3D5AFE"
    readonly property color highlightColor: "#FFFFFF"
    readonly property real highlightOpacity: 0.08

    readonly property int animDuration: 450
    readonly property int animEasing: Easing.OutQuart

    property bool leftBarExpanded: false
    property int dynamicIslandCornerRadius: 30

    property int dynamicIslandExpandedWidth: 420
    property int dynamicIslandExpandedHeight: 130
    property int dynamicIslandCollapsedWidth: 120
    property int collapseTimerDelay: 200
    property int roundedCornerShapeWidth: 20
    property int roundedCornerShapeRadius: 20

    property int appIslandExpandedWidth: 600
    property int appIslandExpandedHeight: 130
    property string appIslandSortMode: "alphabetical" // or none

    property int appIslandDelegateHeight: 130
    property int appIslandDelegateWidth: 80
    property int appIslandDelegateTextMargin: 20

    property real appIslandMinOpacity: 0.5
    property real appIslandMinScale: 0.8
    property int appIslandIconSize: 48
    property int appIslandFontSize: 12
    property int appIslandSpacing: 7
    property int appIslandBuffer: 5

    property int appIslandHighlightAnimDuration: 150

    property string appIslandArrowIndicatorText: "^"
    property int appIslandArrowIndicatorSize: 16
    property int appIslandArrowIndicatorTopMargin: 5

    property int appIslandSearchBarHeight: 40
    property int appIslandSearchBarTopMargin: 10
    property int appIslandSearchBarHorizontalMargin: 20
    property int appIslandSearchBarRadius: 20
    property color appIslandSearchBarColor: "#333333"
    property int appIslandSearchInputHorizontalMargin: 10
    property int appIslandSearchInputFontSize: 16

    property int appIslandScrubberFontSize: 14
    property real appIslandScrubberActiveOpacity: 1.0
    property real appIslandScrubberInactiveOpacity: 0.5
    property real appIslandScrubberActiveScale: 1.5
    property real appIslandScrubberInactiveScale: 1.0
    property int appIslandScrubberPathItemCount: 12
    property int appIslandScrubberDelegateWidth: 20

    property int cavaLoaderMargin: 15
    property int cavaLoaderHeight: 40

    property int pathViewTopMargin: 10
    property int pathViewBottomMargin: 5
    property int delegateLoaderMargin: 20

    property int indicatorRowBottomMargin: 8
    property int indicatorRowSpacing: 6
    property int indicatorDotSize: 6
    property int indicatorDotRadius: 3
    property color indicatorDotColor: "#555"
    property color indicatorDotActiveColor: "white"
    property int indicatorDotAnimationDuration: 150
}
