import QtQuick
import qs.core
import qs.modules.editor
import qs.services.wallpaper.projects

IslandModule {
    required property string screenName

    moduleId: "wallpaper-editor"
    priority: 95
    active: (WallpaperEditorService.opened || WallpaperEditorService.closing || WallpaperEditorService.warmRetained) && WallpaperEditorService.targetScreenName === screenName
    arbitrationActive: (WallpaperEditorService.opened || WallpaperEditorService.closing) && WallpaperEditorService.targetScreenName === screenName
    attention: active && !WallpaperEditorService.closing
    wantsKeyboard: WallpaperEditorService.opened
    lifecycleClassification: "briefly-warm"
    lifecycleAdaptiveEligible: WallpaperEditorService.warmRetained && !WallpaperEditorService.closing
    lifecycleUsageActive: WallpaperEditorService.opened || WallpaperEditorService.closing
    lifecycleEstimatedCostUnits: 80
    lifecycleBasePriority: priority
    lifecycleEvict: reason => WallpaperEditorService.evictWarm(reason)
    collapsedWidth: Design.collapsedWidth
    expandedWidth: Design.editorMaximumWidth
    expandedHeight: Design.editorMaximumHeight
    revealWithExpansion: true

    collapsedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(220)
        preferredWidth: Design.scaledWidth(220)
        maximumWidth: Design.scaledWidth(360)
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.scaledHeight(56)
    }

    expandedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(760)
        preferredWidth: Design.scaledWidth(1280)
        maximumWidth: Design.editorMaximumWidth
        minimumHeight: Design.scaledHeight(520)
        preferredHeight: Design.scaledHeight(800)
        maximumHeight: Design.editorMaximumHeight
    }

    view: Component {
        WallpaperEditorModule {}
    }
}
