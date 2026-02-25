import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root
    
    spacing: 10

    ColumnLayout {
        spacing: 2
        
        Text { 
            id: brightnessHeaderLabel
            text: "BRIGHTNESS"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 8
            font.weight: Font.Black
            font.letterSpacing: 1.5
            opacity: 0.3
            height: 10
            verticalAlignment: Text.AlignBottom
        }
        
        ValueSlider { 
            id: brightnessSlider
            width: 180
            height: 24
            isSliderEnabled: BrightnessManager.isAvailable
            sliderValue: BrightnessManager.level
            sliderIcon: "󰃠"
            sliderBarColor: "#FFCC00"
            onSliderMoved: (value) => BrightnessManager.setLevel(value)
        }
    }

    ColumnLayout {
        spacing: 2
        
        Text { 
            id: volumeHeaderLabel
            text: "VOLUME"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 8
            font.weight: Font.Black
            font.letterSpacing: 1.5
            opacity: 0.3
            height: 10
            verticalAlignment: Text.AlignBottom
        }
        
        ValueSlider { 
            id: volumeSlider
            width: 180
            height: 24
            isSliderEnabled: AudioManager.isAudioAvailable
            sliderValue: AudioManager.volume
            sliderIcon: AudioManager.isMuted ? "󰝟" : "󰕾"
            sliderBarColor: ThemeManager.contentOnBackgroundColor
            onSliderMoved: (value) => AudioManager.setVolume(value)
        }
    }
}
