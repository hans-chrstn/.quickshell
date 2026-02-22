import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

ColumnLayout {
    id: root
    spacing: 12

    ColumnLayout {
        spacing: 4
        Text { 
            text: "BRIGHTNESS"
            color: ThemeService.backgroundContent
            font.pixelSize: 8
            font.weight: Font.Black
            font.letterSpacing: 1.5
            opacity: 0.3
            Layout.leftMargin: 4 
        }
        ControlSlider { 
            width: 180; height: 28
            enabled: BrightnessService.hasBrightness
            value: BrightnessService.brightness
            icon: "󰃠"; barColor: "#FFCC00"
            onMoved: (v) => BrightnessService.setBrightness(v)
        }
    }

    ColumnLayout {
        spacing: 4
        Text { 
            text: "VOLUME"
            color: ThemeService.backgroundContent
            font.pixelSize: 8
            font.weight: Font.Black
            font.letterSpacing: 1.5
            opacity: 0.3
            Layout.leftMargin: 4 
        }
        ControlSlider { 
            width: 180; height: 28
            enabled: AudioService.hasAudio
            value: AudioService.volume
            icon: AudioService.muted ? "󰝟" : "󰕾"; barColor: ThemeService.backgroundContent
            onMoved: (v) => AudioService.setVolume(v)
        }
    }
}