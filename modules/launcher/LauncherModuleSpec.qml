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

    view: Component {
        LauncherModule { }
    }
}
