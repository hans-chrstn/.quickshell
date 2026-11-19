import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services.osd
import qs.services.settings

PanelWindow {
    id: root

    readonly property string screenName: screen?.name || ""
    readonly property bool showing: OsdService.targetScreenName === screenName && OsdService.active
    readonly property var item: OsdService.current
    readonly property color accent: item?.muted ? Theme.textSecondary : item?.kind === "brightness" ? Theme.warning : item?.kind === "microphone" ? Theme.success : Theme.accent

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Design.osdHeight + Design.osdBottomGap + Design.space16
    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    visible: showing

    BackgroundEffect.blurRegion: Region {
        Region {
            item: blurParkingTarget
        }
        Region {
            item: root.showing && SettingsService.enableBlur ? glass : null
            topLeftRadius: glass.cornerRadius
            topRightRadius: glass.cornerRadius
            bottomLeftRadius: glass.cornerRadius
            bottomRightRadius: glass.cornerRadius
        }
    }

    mask: Region {
        item: root.showing ? glass : null
    }

    Item {
        id: blurParkingTarget
        width: 1
        height: 1
        opacity: 0
    }

    GlassCard {
        id: glass
        x: (root.width - width) / 2
        y: OsdService.visible ? Design.space16 : Design.space16 + Design.space24
        width: Design.osdWidth
        height: Design.osdHeight
        cornerRadius: Design.radiusPanel
        backdropAvailable: SettingsService.enableBlur
        emphasis: 1
        opacity: OsdService.visible ? 1 : 0

        Behavior on y {
            enabled: !Design.reducedMotion
            SpatialSpring {
                phase: OsdService.visible ? "enter" : "exit"
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: OsdService.visible ? Design.springEnterFadeDuration : Design.springExitFadeDuration
            }
        }

        IconMark {
            x: Design.space12
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            glyph: root.item?.glyph || "volumeHigh"
            glyphSize: 22
            glyphColor: root.accent
        }

        Text {
            x: 70
            y: 13
            text: root.item?.title || ""
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            font.weight: Font.DemiBold
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: Design.space16
            y: 13
            text: root.item?.valueText || ""
            color: Theme.textPrimary
            font.family: Design.fontMono
            font.pixelSize: Design.typeLabel
            font.weight: Font.DemiBold
        }

        LevelTrack {
            x: 70
            y: 47
            width: parent.width - x - Design.space16
            height: 6
            value: root.item?.muted ? 0 : root.item?.level || 0
            accentColor: root.accent
        }
    }
}
