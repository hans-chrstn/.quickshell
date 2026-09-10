import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.editor
import qs.services.wallpaper.projects

PanelWindow {
    id: root

    readonly property var targetScreen: {
        const name = WallpaperEditorService.targetScreenName
        for (const candidate of Quickshell.screens)
            if (candidate.name === name) return candidate
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    screen: targetScreen
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.namespace: "inspire-wallpaper-editor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WallpaperEditorService.opened
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: panel }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.max(0, Math.min(Design.editorMaximumWidth,
            parent.width - Math.max(24, Design.editorOuterMargin * 2)))
        height: Math.max(0, Math.min(Design.editorMaximumHeight,
            parent.height - Math.max(24, Design.editorOuterMargin * 2)))
        radius: Design.editorPanelRadius
        color: "transparent"
        opacity: WallpaperEditorService.opened ? 1 : 0
        scale: WallpaperEditorService.opened ? 1 : 0.985

        Behavior on opacity {
            NumberAnimation {
                duration: Design.contentRevealDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Design.contentRevealDuration
                easing.type: Easing.OutCubic
            }
        }

        WallpaperEditorSurface { anchors.fill: parent }
    }

    Shortcut {
        sequence: "Escape"
        enabled: WallpaperEditorService.opened
        onActivated: WallpaperEditorService.close()
    }
}
