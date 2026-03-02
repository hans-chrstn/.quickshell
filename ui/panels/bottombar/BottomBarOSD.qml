import QtQuick
import qs.core
import qs.ui.shared

ValueIndicatorPill {
    id: root
    
    width: ThemeManager.osdPillWidth
    height: ThemeManager.osdPillHeight
    
    property string displayType: "volume"
    progressColor: displayType === "brightness" ? "#FFCC00" : ThemeManager.accentColor
    
    readonly property bool isHovered: hoverInteractionHandler.hovered
    onIsHoveredChanged: {
        if (isHovered) {
            hideTimer.stop()
        } else if (isPillActive) {
            hideTimer.restart()
        }
    }

    HoverHandler {
        id: hoverInteractionHandler
    }

    onIconInteracted: {
        if (displayType === "volume") {
            if (AudioManager.volume > 0) {
                AudioManager.setVolume(0)
            } else {
                AudioManager.setVolume(AudioManager.previousVolume > 0 ? AudioManager.previousVolume : 0.5)
            }
        }
    }
    
    onValueAdjusted: (val) => {
        if (displayType === "volume") {
            AudioManager.setVolume(val)
        } else {
            BrightnessManager.setLevel(val)
        }
        hideTimer.restart() 
    }

    Timer { 
        id: hideTimer
        interval: ThemeManager.osdHideDelay
        onTriggered: {
            if (!root.isHovered) {
                root.isPillActive = false
            }
        }
    }

    function show(newType, newIcon, newVal) {
        root.displayType = newType
        root.statusIcon = newIcon
        root.indicatorValue = newVal
        root.isPillActive = true
        hideTimer.restart()
    }

    property bool isOsdReady: false
    Timer { 
        interval: 1500
        running: true
        onTriggered: {
            root.isOsdReady = true
        }
    }

    Connections {
        target: AudioManager
        function onVolumeChanged() {
            if (root.isOsdReady) {
                root.show("volume", AudioManager.isMuted ? ThemeManager.iconMute : ThemeManager.iconVolume, AudioManager.volume)
            }
        }
    }

    Connections {
        target: BrightnessManager
        function onLevelChanged() {
            if (root.isOsdReady) {
                root.show("brightness", ThemeManager.iconBrightness, BrightnessManager.level)
            }
        }
    }
}
