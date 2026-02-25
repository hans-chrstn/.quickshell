import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

ColumnLayout {
    id: root
    spacing: 10

    ColumnLayout {
        spacing: 2
        Text { 
            text: "BRIGHTNESS"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 8
            font.weight: Font.Black
            font.letterSpacing: 1.5
            opacity: 0.3
            height: 10
            verticalAlignment: Text.AlignBottom
        }
        ControlSlider { 
            width: 180; height: 24
            enabled: BrightnessManager.isAvailable
            value: BrightnessManager.level
            icon: "󰃠"; barColor: "#FFCC00"
            onMoved: (v) => BrightnessManager.setLevel(v)
        }
    }

    ColumnLayout {
        spacing: 2
        Text { 
            text: "VOLUME"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 8
            font.weight: Font.Black
            font.letterSpacing: 1.5
            opacity: 0.3
            height: 10
            verticalAlignment: Text.AlignBottom
        }
        ControlSlider { 
            width: 180; height: 24
            enabled: AudioManager.isAudioAvailable
            value: AudioManager.volume
            icon: AudioManager.isMuted ? "󰝟" : "󰕾"; barColor: ThemeManager.contentOnBackgroundColor
            onMoved: (v) => AudioManager.setVolume(v)
        }
    }
}
