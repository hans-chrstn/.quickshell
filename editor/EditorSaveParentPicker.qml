import QtQuick
import Quickshell
import qs.components.filepicker
import qs.services.wallpaper.projects

FilePicker {
    mode: "directory"
    initialPath: WallpaperEditorService.saveParentPath.length > 0
        ? WallpaperEditorService.saveParentPath
        : (Quickshell.env("HOME") || "/")
    onAccepted: paths => WallpaperEditorService.chooseSaveParent(paths[0])
    onCanceled: WallpaperEditorService.finishChoosingSaveParent()
}
