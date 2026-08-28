import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property bool active: false

    spacing: 15

    StyledLabel {
        text: "Global Outputs & Inputs"
        type: "label"
        font.weight: Font.Bold
        opacity: 0.8
    }

    PwObjectTracker {
        id: sinkTracker
        objects: {
            if (root.active && AudioManager.defaultSink) {
                return [AudioManager.defaultSink]
            }
            return []
        }
    }

    PwObjectTracker {
        id: sourceTracker
        objects: {
            if (root.active && AudioManager.defaultSource) {
                return [AudioManager.defaultSource]
            }
            return []
        }
    }

    readonly property real outputVolume: {
        let sink = AudioManager.defaultSink
        if (root.active && sink && sink.ready && sink.audio) {
            return sink.audio.volume
        }
        return 0.0
    }

    readonly property bool outputMuted: {
        let sink = AudioManager.defaultSink
        if (root.active && sink && sink.ready && sink.audio) {
            return sink.audio.muted
        }
        return false
    }

    readonly property real inputVolume: {
        let source = AudioManager.defaultSource
        if (root.active && source && source.ready && source.audio) {
            return source.audio.volume
        }
        return 0.0
    }

    readonly property bool inputMuted: {
        let source = AudioManager.defaultSource
        if (root.active && source && source.ready && source.audio) {
            return source.audio.muted
        }
        return false
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledLabel {
                text: "Output"
                type: "caption"
                opacity: 0.5
            }

            DeviceSelectorDropdown {
                id: outputSelector
                Layout.fillWidth: true
                icon: ThemeManager.iconAudioOutput
                currentId: AudioManager.defaultSink ? AudioManager.defaultSink.id : -1
                model: {
                    let arr = []
                    if (AudioManager.sinks) {
                        for (let i = 0; i < AudioManager.sinks.count; i++) {
                            arr.push(AudioManager.sinks.get(i))
                        }
                    }
                    return arr
                }

                onDeviceSelected: (deviceId, modelData) => {
                    if (modelData && modelData.nodeObj) {
                        AudioManager.selectSink(modelData.nodeObj)
                    }
                }
            }

            ValueSlider {
                Layout.fillWidth: true
                sliderValue: root.outputVolume
                sliderIcon: {
                    if (root.outputMuted) {
                        return ThemeManager.iconMute
                    }
                    return ThemeManager.iconVolume
                }
                sliderBarColor: ThemeManager.accentColor
                onSliderMoved: (value) => {
                    AudioManager.setVolume(value)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledLabel {
                text: "Input"
                type: "caption"
                opacity: 0.5
            }

            DeviceSelectorDropdown {
                id: inputSelector
                Layout.fillWidth: true
                icon: ThemeManager.iconAudioInput
                currentId: AudioManager.defaultSource ? AudioManager.defaultSource.id : -1
                model: {
                    let arr = []
                    if (AudioManager.sources) {
                        for (let i = 0; i < AudioManager.sources.count; i++) {
                            arr.push(AudioManager.sources.get(i))
                        }
                    }
                    return arr
                }

                onDeviceSelected: (deviceId, modelData) => {
                    if (modelData && modelData.nodeObj) {
                        AudioManager.selectSource(modelData.nodeObj)
                    }
                }
            }

            ValueSlider {
                Layout.fillWidth: true
                sliderValue: root.inputVolume
                sliderIcon: {
                    if (root.inputMuted) {
                        return ThemeManager.iconMute
                    }
                    return ThemeManager.iconVolume
                }
                sliderBarColor: ThemeManager.accentColor
                onSliderMoved: (value) => {
                    let source = AudioManager.defaultSource
                    if (source && source.ready && source.audio) {
                        if (Math.abs(source.audio.volume - value) > 0.001) {
                            if (source.audio.muted && value > 0) {
                                source.audio.muted = false
                            }
                            source.audio.volume = value
                        }
                        if (value === 0 && !source.audio.muted) {
                            source.audio.muted = true
                        }
                    }
                }
            }
        }
    }
}
