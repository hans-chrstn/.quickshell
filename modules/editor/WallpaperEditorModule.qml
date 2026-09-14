import QtQuick
import qs.components
import qs.core
import qs.editor
import qs.services.wallpaper.projects

Item {
    id: root

    property QtObject context: null
    property bool escapeHeld: false
    readonly property real availableWidth: Number(context?.availableWidth) || 0
    readonly property real availableHeight: Number(context?.availableHeight) || 0
    readonly property real horizontalAllowance: 2 * (Design.editorOuterMargin + Design.wing + Design.expandedContentPadding)
    readonly property real verticalAllowance: 2 * (Design.editorOuterMargin + Design.expandedContentPadding)
    readonly property real collapsedImplicitWidth: 160
    readonly property real collapsedImplicitHeight: 22
    readonly property real expandedImplicitWidth: Math.max(0, Math.min(Design.editorMaximumWidth - 2 * (Design.wing + Design.expandedContentPadding), availableWidth - horizontalAllowance))
    readonly property real expandedImplicitHeight: Math.max(0, Math.min(Design.editorMaximumHeight - 2 * Design.expandedContentPadding, availableHeight - verticalAllowance))

    focus: true
    enabled: WallpaperEditorService.opened
    Component.onCompleted: focusRetrier.startFocus()

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: WallpaperEditorService
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (root.escapeHeld || event.isAutoRepeat) {
                event.accepted = true;
                return;
            }
            root.escapeHeld = true;
            if (WallpaperEditorOpenService.pickerOpened)
                WallpaperEditorOpenService.cancelPicker();
            else if (WallpaperEditorService.saveAsOpened)
                WallpaperEditorService.closeSaveAs();
            else if (WallpaperEditorService.pickerOpened)
                WallpaperEditorService.cancelPicker();
            else
                WallpaperEditorService.close();
            event.accepted = true;
        }
    }

    Keys.onReleased: event => {
        if (event.key === Qt.Key_Escape) {
            root.escapeHeld = false;
            event.accepted = true;
        }
    }

    Connections {
        target: WallpaperEditorService
        function onSaveAsOpenedChanged() {
            if (!target.saveAsOpened && target.opened)
                Qt.callLater(focusRetrier.startFocus);
        }
        function onPickerOpenedChanged() {
            if (!target.pickerOpened && target.opened)
                Qt.callLater(focusRetrier.startFocus);
        }
    }

    Connections {
        target: WallpaperEditorOpenService
        function onPickerOpenedChanged() {
            if (!target.pickerOpened && WallpaperEditorService.opened)
                Qt.callLater(focusRetrier.startFocus);
        }
    }

    WallpaperEditorSurface {
        anchors.fill: parent
        embeddedInIsland: true
    }
}
