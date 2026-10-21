import QtQuick
import qs.core
import qs.modules.audio
import qs.services.audio

IslandModule {
    required property string screenName

    moduleId: "audio-privacy"
    priority: 45
    active: AudioPrivacyPresentationService.active && AudioPrivacyPresentationService.targetScreenName === screenName
    attention: active
    collapsedWidth: Design.scaledWidth(260)
    collapsedHeight: Design.collapsedHeight
    expandedWidth: Design.scaledWidth(440)
    expandedHeight: Design.scaledHeight(78)
    expandOnAttention: false
    revealWithExpansion: false

    collapsedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(220)
        preferredWidth: Design.scaledWidth(260)
        maximumWidth: Design.scaledWidth(350)
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.scaledHeight(52)
    }

    expandedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(380)
        preferredWidth: Design.scaledWidth(440)
        maximumWidth: Design.scaledWidth(520)
        minimumHeight: Design.scaledHeight(72)
        preferredHeight: Design.scaledHeight(78)
        maximumHeight: Design.scaledHeight(88)
    }

    view: Component {
        AudioPrivacyModule {}
    }
}
