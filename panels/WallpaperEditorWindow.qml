import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.lifecycle
import qs.core
import qs.modules.editor
import qs.services.settings
import qs.services.wallpaper.projects

PanelWindow {
    id: root

    readonly property string screenName: screen?.name || ""
    readonly property bool showing: WallpaperEditorService.opened && WallpaperEditorService.targetScreenName === screenName
    readonly property bool closing: WallpaperEditorService.closing && WallpaperEditorService.targetScreenName === screenName
    readonly property bool retained: WallpaperEditorService.warmRetained && WallpaperEditorService.targetScreenName === screenName

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true
    focusable: showing
    visible: showing || closing

    BackgroundEffect.blurRegion: Region {
        Region {
            item: blurParkingTarget
        }
        Region {
            item: root.visible && SettingsService.enableBlur ? editorGlass : null
            topLeftRadius: editorGlass.cornerRadius
            topRightRadius: editorGlass.cornerRadius
            bottomLeftRadius: editorGlass.cornerRadius
            bottomRightRadius: editorGlass.cornerRadius
        }
    }

    mask: Region {
        item: root.visible ? editorGlass : null
    }

    Item {
        id: blurParkingTarget
        width: 1
        height: 1
        opacity: 0
    }

    GlassCard {
        id: editorGlass
        x: (root.width - width) / 2
        y: (root.height - height) / 2 + (root.showing ? 0 : Design.space24)
        width: Math.min(Design.editorMaximumWidth, root.width - Design.editorOuterMargin * 2)
        height: Math.min(Design.editorMaximumHeight, root.height - Design.editorOuterMargin * 2)
        cornerRadius: Design.radiusWorkspace
        backdropAvailable: SettingsService.enableBlur
        visible: root.visible
        opacity: root.showing ? 1 : 0

        Behavior on y {
            enabled: !Design.reducedMotion
            SpatialSpring {
                phase: root.showing ? "enter" : "exit"
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.showing ? Design.springEnterFadeDuration : Design.springExitFadeDuration
            }
        }

        LifecycleLoader {
            anchors.fill: parent
            anchors.margins: Design.space8
            resourceId: "wallpaper.editor-window." + root.screenName
            owner: "wallpaper-editor-window"
            restorationSource: "WallpaperProjectService and WallpaperDraftWorkspaceService"
            classification: "briefly-warm"
            adaptiveEligible: root.retained
            estimatedCostUnits: 80
            basePriority: 95
            requestedActive: root.showing || root.retained
            usageActive: root.showing || root.closing
            retentionReason: root.showing ? "editor-open" : root.retained ? "editor-warm" : ""
            evictionReason: requestedActive ? "" : "editor-closed"
            onAdaptiveEvictionRequested: reason => WallpaperEditorService.evictWarm(reason)
            sourceComponent: Component {
                WallpaperEditorModule {}
            }
        }
    }
}
