import QtQuick
import qs.components
import qs.core
import qs.services.audio

Rectangle {
    id: root

    required property string role
    readonly property bool outputRole: role === "output"
    readonly property var audioState: outputRole ? AudioService.output : AudioService.input
    readonly property bool available: audioState?.available ?? false
    readonly property bool muted: audioState?.muted ?? false
    readonly property real level: Number(audioState?.volume) || 0
    readonly property real ceiling: Number(outputRole ? AudioService.controlPolicy?.outputCeiling : AudioService.controlPolicy?.inputCeiling) || 1
    readonly property string title: outputRole ? "Output" : "Input"
    readonly property string glyph: outputRole ? muted ? "volumeMuted" : level > 0.45 ? "volumeHigh" : "volumeLow" : muted ? "microphoneMuted" : "microphone"

    radius: Design.radiusGrouped
    color: Theme.fillSubtle
    border.color: Theme.separatorQuiet
    opacity: available ? 1 : 0.48

    Rectangle {
        x: Design.space16
        y: Design.space16
        width: 42
        height: 42
        radius: width / 2
        color: Theme.alpha(Theme.accent, 0.13)

        IslandGlyph {
            anchors.centerIn: parent
            width: 22
            height: 22
            name: root.glyph
            glyphColor: Theme.accent
        }
    }

    Text {
        x: 70
        y: Design.space20
        text: root.title
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: Design.typeTitle
        font.weight: Font.DemiBold
    }

    Text {
        x: 70
        y: 43
        width: parent.width - x - Design.space12
        text: root.available ? String(root.audioState?.name || "Default device") : "Unavailable"
        color: Theme.textSecondary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
        elide: Text.ElideMiddle
        textFormat: Text.PlainText
    }

    Text {
        x: Design.space16
        y: Math.max(82, parent.height * 0.38)
        text: root.muted ? "Muted" : Math.round(root.level * 100) + "%"
        color: root.muted ? Theme.textSecondary : Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: Design.typeDisplay + 14
        font.weight: Font.Medium
    }

    GlyphButton {
        id: muteButton
        x: Design.space12
        y: parent.height - height - Design.space16
        width: 42
        height: 42
        glyph: root.glyph
        glyphSize: 20
        primary: root.muted
        enabled: root.available
        accessibleName: (root.muted ? "Unmute " : "Mute ") + root.title.toLowerCase()
        onActivated: AudioService.setMasterMuted(root.role, !root.muted)
    }

    AudioLevelSlider {
        x: muteButton.x + muteButton.width + Design.space8
        y: muteButton.y
        width: parent.width - x - Design.space16
        height: muteButton.height
        enabled: root.available
        from: 0
        to: Math.max(0.01, root.ceiling)
        stepSize: 0.01
        value: Math.max(from, Math.min(to, root.level))
        accentColor: root.muted ? Theme.textTertiary : Theme.accent
        Accessible.name: root.title + " volume"
        onLevelEdited: value => AudioService.setMasterVolume(root.role, value)
        onStepRequested: steps => AudioService.adjustMasterVolume(root.role, steps)
    }
}
