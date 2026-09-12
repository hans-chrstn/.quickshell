import QtQuick
import qs.core
import qs.modules.notifications
import qs.services.notifications

IslandModule {
    required property string screenName

    moduleId: "notification"
    priority: 60
    active: NotificationService.current !== null
        && NotificationService.current.screenName === screenName
    attention: active && NotificationService.presentationVisible
    collapsedWidth: Design.scaledWidth(260)
    expandedWidth: Design.scaledWidth(440)
    expandedHeight: Design.scaledHeight(96)
    revealWithExpansion: false

    collapsedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(220)
        preferredWidth: Design.scaledWidth(260)
        maximumWidth: Design.scaledWidth(360)
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.scaledHeight(56)
    }

    expandedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(320)
        preferredWidth: Design.scaledWidth(440)
        maximumWidth: Design.scaledWidth(600)
        minimumHeight: Design.scaledHeight(72)
        preferredHeight: Design.scaledHeight(96)
        maximumHeight: Design.scaledHeight(160)
    }

    view: Component { NotificationModule {} }
}
