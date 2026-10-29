pragma Singleton

import QtQuick
import Quickshell
import qs.services.settings

Singleton {
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontText: "SF Pro Text"
    readonly property string fontMono: "SF Mono"

    readonly property int typeDisplay: 22
    readonly property int typeTitle: 17
    readonly property int typeBody: 13
    readonly property int typeLabel: 11
    readonly property int typeCaption: 10

    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24

    readonly property int radiusControl: 10
    readonly property int radiusGrouped: 14
    readonly property int radiusPanel: 22
    readonly property int radiusWorkspace: 28
    readonly property int radiusCapsule: 999
    readonly property int controlHeight: 32
    readonly property int minimumTouchTarget: 36

    readonly property int motionPressDuration: 80
    readonly property int motionStateDuration: 140
    readonly property int motionControlDuration: 170
    readonly property int motionTravelDuration: 190
    readonly property int motionExitDuration: 220
    readonly property int motionStandardEasing: Easing.OutCubic
    readonly property int motionSpatialEasing: Easing.InOutCubic
    readonly property var motionControlCurve: [0.2, 0, 0, 1, 1, 1]

    readonly property int wing: SettingsService.islandWing
    readonly property int collapsedWidth: SettingsService.islandCollapsedWidth
    readonly property int collapsedHeight: 34
    readonly property int defaultExpandedWidth: scaledWidth(440)
    readonly property int defaultExpandedHeight: scaledHeight(154)
    readonly property int triggerHeight: 6
    readonly property int bodyRadius: SettingsService.islandBodyRadius
    readonly property int expandedBodyRadius: Math.max(bodyRadius, scaledHeight(28))
    readonly property int contentHorizontalPadding: 14
    readonly property int contentVerticalPadding: 6
    readonly property int expandedContentPadding: 18
    readonly property int editorMaximumWidth: 1600
    readonly property int editorMaximumHeight: 1040
    readonly property int editorOuterMargin: 44
    readonly property int editorPanelRadius: 28
    readonly property int editorSectionRadius: 18
    readonly property int editorGap: 12
    readonly property int editorWarmRetentionMs: 30000

    readonly property int revealDuration: SettingsService.revealDuration
    readonly property int resizeDuration: SettingsService.resizeDuration
    readonly property int islandMorphEasing: motionSpatialEasing
    readonly property int contentRevealDuration: SettingsService.contentRevealDuration
    readonly property int attentionExpandDelay: SettingsService.attentionExpandDelay
    readonly property int moduleCloseDuration: SettingsService.moduleCloseDuration
    readonly property int moduleHandoffDuration: SettingsService.moduleHandoffDuration
    readonly property int expandDelay: SettingsService.expandDelay
    readonly property int hideDelay: SettingsService.hideDelay

    function scaledWidth(baseline) {
        return Math.round(baseline * SettingsService.islandWidthPercent / 100);
    }

    function scaledHeight(baseline) {
        return Math.round(baseline * SettingsService.islandHeightPercent / 100);
    }
}
