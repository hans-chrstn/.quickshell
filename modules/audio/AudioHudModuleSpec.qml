import QtQuick
import qs.core
import qs.modules.audio
import qs.services.audio

IslandModule {
    required property string screenName

    moduleId: "audio-hud"
    priority: 50
    active: AudioHudService.active && AudioHudService.targetScreenName === screenName
    attention: AudioHudService.visible && AudioHudService.targetScreenName === screenName
    collapsedWidth: Design.scaledWidth(240)
    collapsedHeight: Design.collapsedHeight
    expandedWidth: Design.scaledWidth(240)
    expandedHeight: Design.collapsedHeight
    expandOnAttention: false
    revealWithExpansion: false

    collapsedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(220)
        preferredWidth: Design.scaledWidth(240)
        maximumWidth: Design.scaledWidth(320)
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.scaledHeight(52)
    }

    expandedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(220)
        preferredWidth: Design.scaledWidth(240)
        maximumWidth: Design.scaledWidth(320)
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.scaledHeight(52)
    }

    view: Component {
        AudioHudModule {}
    }
}
