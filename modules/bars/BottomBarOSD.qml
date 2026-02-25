import QtQuick
import qs.services
import qs.components

ControlPill {
    id: root
    
    width: ThemeManager.osdPillWidth
    height: ThemeManager.osdPillHeight
    
    property string type: "volume"
    barColor: type === "brightness" ? "#FFCC00" : ThemeManager.accentColor
    
    readonly property bool hovered: hOsd.hovered
    onHoveredChanged: if (hovered) hideTimer.stop()
    else if (active) hideTimer.restart()

    HoverHandler { id: hOsd }

    onIconClicked: {
        if (type === "volume") {
            if (AudioManager.volume > 0) AudioManager.setVolume(0)
            else AudioManager.setVolume(AudioManager.previousVolume > 0 ? AudioManager.previousVolume : 0.5)
        }
    }
    
    onMoved: (val) => {
        if (type === "volume") AudioManager.setVolume(val)
        else BrightnessManager.setLevel(val)
        hideTimer.restart() 
    }

    Timer { id: hideTimer; interval: ThemeManager.osdHideDelay; onTriggered: if (!root.hovered) root.active = false }

    function show(newType, newIcon, newVal) {
        root.type = newType
        root.icon = newIcon
        root.value = newVal
        root.active = true
        hideTimer.restart()
    }

    property bool osdReady: false
    Timer { interval: 1500; running: true; onTriggered: root.osdReady = true }

    Connections {
        target: AudioManager
        function onVolumeChanged() { if (root.osdReady) root.show("volume", AudioManager.isMuted ? "󰝟" : "󰕾", AudioManager.volume) }
    }

    Connections {
        target: BrightnessManager
        function onLevelChanged() { if (root.osdReady) root.show("brightness", "󰃠", BrightnessManager.level) }
    }
}