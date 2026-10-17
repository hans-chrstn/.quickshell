import QtQuick
import qs.core
import qs.modules.launcher
import qs.services.launcher

IslandModule {
    required property string screenName

    moduleId: "launcher"
    priority: 80
    active: (LauncherService.opened || LauncherService.closing)
        && LauncherService.targetScreenName === screenName
    attention: active
        && !LauncherService.closing
    wantsKeyboard: LauncherService.opened
    collapsedWidth: Design.collapsedWidth
    expandedWidth: Design.scaledWidth(680)
    expandedHeight: Design.scaledHeight(430)
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
        minimumWidth: Design.scaledWidth(560)
        preferredWidth: Design.scaledWidth(680)
        maximumWidth: Design.scaledWidth(900)
        minimumHeight: Design.scaledHeight(320)
        preferredHeight: Design.scaledHeight(430)
        maximumHeight: Design.scaledHeight(520)
    }

    view: Component {
        LauncherModule { }
    }
}
