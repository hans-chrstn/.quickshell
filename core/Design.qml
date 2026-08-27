pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontText: "SF Pro Text"
    readonly property string fontMono: "SF Mono"

    readonly property color island: "#e6101116"
    readonly property color islandExpanded: "#ed111319"
    readonly property color glassStroke: "#38ffffff"
    readonly property color glassHighlight: "#24ffffff"
    readonly property color glassShade: "#24000000"
    readonly property color surface: "#1c1c1e"
    readonly property color surfaceRaised: "#2c2c2e"
    readonly property color text: "#ffffff"
    readonly property color textMuted: "#8e8e93"
    readonly property color separator: "#38383a"
    readonly property color blue: "#0a84ff"
    readonly property color green: "#30d158"
    readonly property color yellow: "#ffd60a"
    readonly property color red: "#ff453a"

    readonly property int wing: 16
    readonly property int collapsedWidth: 184
    readonly property int collapsedHeight: 34
    readonly property int defaultExpandedWidth: 440
    readonly property int defaultExpandedHeight: 154
    readonly property int triggerHeight: 6
    readonly property int bodyRadius: 20
    readonly property int contentHorizontalPadding: 14
    readonly property int contentVerticalPadding: 6
    readonly property int expandedContentPadding: 18

    readonly property int revealDuration: 300
    readonly property int resizeDuration: 520
    readonly property int contentRevealDuration: 180
    readonly property int attentionExpandDelay: 170
    readonly property int moduleCloseDuration: 440
    readonly property int expandDelay: 420
    readonly property int hideDelay: 1200
}
