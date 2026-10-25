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
        minimumWidth: Design.scaledWidth(440)
        preferredWidth: Design.scaledWidth(520)
        maximumWidth: Design.scaledWidth(720)
        minimumHeight: Design.scaledHeight(180)
        preferredHeight: Design.scaledHeight(210)
        maximumHeight: Design.scaledHeight(320)
    }

    view: Component { SessionModule { } }
}
