import QtQuick
import qs.core
import qs.modules.audio
import qs.services.audio

IslandModule {
    required property string screenName

    moduleId: "audio-control"
    priority: 82
    active: (AudioPanelService.opened || AudioPanelService.closing) && AudioPanelService.targetScreenName === screenName
    attention: active && !AudioPanelService.closing
    wantsKeyboard: AudioPanelService.opened
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
        minimumWidth: Design.scaledWidth(680)
        preferredWidth: Design.scaledWidth(720)
        maximumWidth: Design.scaledWidth(860)
        minimumHeight: Design.scaledHeight(480)
        preferredHeight: Design.scaledHeight(520)
        maximumHeight: Design.scaledHeight(600)
    }

    view: Component {
        AudioControlModule {}
    }
}
