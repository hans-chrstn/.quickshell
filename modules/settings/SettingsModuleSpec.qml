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
    collapsedWidth: 220
    expandedWidth: 700
    expandedHeight: 430
    revealWithExpansion: true

    view: Component { SettingsModule { } }
}
