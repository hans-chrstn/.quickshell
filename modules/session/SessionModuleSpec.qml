import QtQuick
import qs.core
import qs.modules.session
import qs.services.session

IslandModule {
    required property string screenName

    moduleId: "session"
    priority: 90
    active: (SessionService.opened || SessionService.closing)
        && SessionService.targetScreenName === screenName
    attention: active && !SessionService.closing
    wantsKeyboard: SessionService.opened
    collapsedWidth: Design.collapsedWidth
    expandedWidth: Design.scaledWidth(520)
    expandedHeight: Design.scaledHeight(210)
    revealWithExpansion: true

    view: Component { SessionModule { } }
}
