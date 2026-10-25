import QtQuick
import Quickshell.Hyprland

QtObject {
    property GlobalShortcut outputVolumeUp: GlobalShortcut {
        appid: "new-shell"
        name: "audio-output-volume-up"
        description: "Raise the default output volume"
        onPressed: AudioService.adjustMasterVolume("output", 1)
    }

    property GlobalShortcut outputVolumeDown: GlobalShortcut {
        appid: "new-shell"
        name: "audio-output-volume-down"
        description: "Lower the default output volume"
        onPressed: AudioService.adjustMasterVolume("output", -1)
    }

    property GlobalShortcut outputMute: GlobalShortcut {
        appid: "new-shell"
        name: "audio-output-mute"
        description: "Toggle mute for the default output"
        onPressed: AudioService.setMasterMuted("output", !AudioService.output.muted)
    }

    property GlobalShortcut inputMute: GlobalShortcut {
        appid: "new-shell"
        name: "audio-input-mute"
        description: "Toggle mute for the default input"
        onPressed: AudioService.setMasterMuted("input", !AudioService.input.muted)
    }
}
