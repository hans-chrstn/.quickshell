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
    collapsedWidth: 220
    expandedWidth: 680
    expandedHeight: 430

    view: Component {
        LauncherModule { }
    }
}
