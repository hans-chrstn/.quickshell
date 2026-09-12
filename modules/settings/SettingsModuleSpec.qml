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

    view: Component { SettingsModule { } }
}
