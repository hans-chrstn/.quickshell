import QtQuick
import qs.core
import qs.modules.settings
import qs.services.settings

IslandModule {
    required property string screenName

    moduleId: "settings"
    priority: 85
    active: (SettingsService.opened || SettingsService.closing)
        && SettingsService.targetScreenName === screenName
    attention: active && !SettingsService.closing
    wantsKeyboard: SettingsService.opened
    collapsedWidth: Design.collapsedWidth
    expandedWidth: Design.scaledWidth(750)
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
        minimumWidth: Design.scaledWidth(620)
        preferredWidth: Design.scaledWidth(750)
        maximumWidth: Design.scaledWidth(1000)
        minimumHeight: Design.scaledHeight(360)
        preferredHeight: Design.scaledHeight(430)
        maximumHeight: Design.scaledHeight(720)
    }

    view: Component { SettingsModule { } }
}
