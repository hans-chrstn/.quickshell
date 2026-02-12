pragma Singleton
import QtQuick

// Will be used later in a settings widget

QtObject {
    readonly property int thickness: 15
    readonly property int cornerRadius: 10
    readonly property color color: "#222222"

    readonly property int animDuration: 350
    readonly property int animEasing: Easing.OutQuint

    property bool leftBarExpanded: false
    property int dynamicIslandCornerRadius: 30

    // Dynamic Island
    property int dynamicIslandExpandedWidth: 420
    property int dynamicIslandExpandedHeight: 130
    property int dynamicIslandCollapsedWidth: 120
    property int collapseTimerDelay: 200
    property int roundedCornerShapeWidth: 20
    property int roundedCornerShapeRadius: 20

    // App Island
    property int appIslandExpandedWidth: 600
    property int appIslandExpandedHeight: 200


    // Cava Loader
    property int cavaLoaderMargin: 15
    property int cavaLoaderHeight: 40

    // Path View
    property int pathViewTopMargin: 10
    property int pathViewBottomMargin: 5
    property int delegateLoaderMargin: 20

    // Indicator
    property int indicatorRowBottomMargin: 8
    property int indicatorRowSpacing: 6
    property int indicatorDotSize: 6
    property int indicatorDotRadius: 3
    property color indicatorDotColor: "#555"
    property color indicatorDotActiveColor: "white"
    property int indicatorDotAnimationDuration: 150
}
