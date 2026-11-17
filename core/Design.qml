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
    readonly property bool reducedMotion: Quickshell.env("QS_REDUCED_MOTION") === "1"

    function motionDuration(duration) {
        return reducedMotion ? 0 : Math.max(0, duration);
    }

    readonly property int motionPressDuration: motionDuration(80)
    readonly property int motionStateDuration: motionDuration(140)
    readonly property int motionControlDuration: motionDuration(170)
    readonly property int motionTravelDuration: motionDuration(190)
    readonly property int motionExitDuration: motionDuration(220)
    readonly property int motionStandardEasing: Easing.OutCubic
    readonly property int motionSpatialEasing: Easing.InOutCubic
    readonly property var motionControlCurve: [0.2, 0, 0, 1, 1, 1]

    readonly property real springEnterStrength: 1.65
    readonly property real springEnterDamping: 0.33
    readonly property real springEnterMass: 1.05
    readonly property real springExitStrength: 1.9
    readonly property real springExitDamping: 0.44
    readonly property real springExitMass: 1.0
    readonly property real springMorphStrength: 2.0
    readonly property real springMorphDamping: 0.38
    readonly property real springMorphMass: 0.92
    readonly property real springPixelEpsilon: 0.25
    readonly property int springEnterFadeDuration: motionDuration(310)
    readonly property int springExitFadeDuration: motionDuration(480)
    readonly property int springViewRetireDelay: 950
    readonly property int islandHoverLeaveDelay: 650
    readonly property int springContentSwapDelay: 140
    readonly property int springContentFadeOutDuration: motionDuration(110)
    readonly property int springContentFadeInDuration: motionDuration(210)
    readonly property int audioLiquidFrameInterval: 33
    readonly property real audioLiquidPhaseStep: 0.075
    readonly property real audioLiquidResponse: 0.19
    readonly property real audioLiquidBaseAmplitude: 3.5
    readonly property real audioLiquidPeakAmplitude: 9
    readonly property real audioLiquidUpperOpacity: 0.13
    readonly property real audioLiquidLowerOpacity: 0.20
    readonly property real mediaScrubStrokeWidth: 5
    readonly property real mediaScrubPlayedFillOpacity: 0.22
    readonly property real mediaScrubUnplayedFillOpacity: 0.10
    readonly property real mediaScrubBaseAmplitude: 1.2
    readonly property real mediaScrubPeakAmplitude: 3.4
    readonly property real mediaScrubLowerDepth: 8.5
    readonly property real mediaScrubLowerAmplitude: 2
    readonly property real mediaTrackRevealScale: 0.94
    readonly property int mediaTrackRevealDuration: motionDuration(300)
    readonly property int mediaTrackRevealEasing: Easing.OutBack
    readonly property int weatherPulseDuration: motionDuration(820)
    readonly property int notificationRowHeight: 48
    readonly property int launcherRowHeight: 46
    readonly property int launcherActionHeight: 35
    readonly property int launcherResultStagger: motionDuration(24)
    readonly property int launcherResultFadeDuration: motionDuration(240)
    readonly property real launcherResultEnterScale: 0.95
    readonly property int launcherCaretBlinkDuration: motionDuration(520)
    readonly property int launcherDetailIconSize: 64
    readonly property int launcherPrimaryActionSize: 44
    readonly property int controlRailWidth: 64
    readonly property int controlRailButtonSize: 42
    readonly property int controlRailItemGap: 9
    readonly property int controlRailOuterGap: 12
    readonly property int controlRailEdgeWidth: 9
    readonly property int controlBodyWidth: 650
    readonly property int controlBodyHeight: 520
    readonly property int controlRailHideDelay: 620
    readonly property int controlPageRevealDelay: motionDuration(220)

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

    readonly property int revealDuration: motionDuration(SettingsService.revealDuration)
    readonly property int resizeDuration: motionDuration(SettingsService.resizeDuration)
    readonly property int islandMorphEasing: motionSpatialEasing
    readonly property int contentRevealDuration: motionDuration(SettingsService.contentRevealDuration)
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
