pragma Singleton
import QtQuick
import Quickshell
import qs.core

Singleton {
    id: root

    property bool active: false
    property string currentType: "volume"
    property real currentValue: 0.0
    property string currentIcon: ""

    property bool _isReady: false

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.active = false
    }

    function show(type, value, icon) {
        if (!root._isReady) return
        
        root.currentType = type
        root.currentValue = value
        root.currentIcon = icon
        root.active = true
        hideTimer.restart()
    }

    Connections {
        target: AudioManager
        function onVolumeChanged() {
            root.show(
                "volume", 
                AudioManager.volume, 
                AudioManager.isMuted ? ThemeManager.iconMute : ThemeManager.iconVolume
            )
        }
    }

    Connections {
        target: BrightnessManager
        function onLevelChanged() {
            root.show(
                "brightness", 
                BrightnessManager.level, 
                ThemeManager.iconBrightness
            )
        }
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: root._isReady = true
    }
}
