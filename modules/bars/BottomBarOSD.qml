import QtQuick
import qs.services
import qs.components

ControlPill {
    id: root
    
    width: ThemeService.osdPillWidth
    height: ThemeService.osdPillHeight
    
    property string type: "volume"
    barColor: type === "brightness" ? "#FFCC00" : ThemeService.accentColor
    
    readonly property bool hovered: hOsd.hovered
    onHoveredChanged: if (hovered) hideTimer.stop()
    else if (active) hideTimer.restart()

    HoverHandler { id: hOsd }

    onIconClicked: {
        if (type === "volume") {
            if (AudioService.volume > 0) AudioService.setVolume(0)
            else AudioService.setVolume(AudioService.lastVolume > 0 ? AudioService.lastVolume : 0.5)
        }
    }
    
    onMoved: (val) => {
        if (type === "volume") AudioService.setVolume(val)
        else BrightnessService.setBrightness(val)
        hideTimer.restart() 
    }

    Timer { id: hideTimer; interval: ThemeService.osdHideDelay; onTriggered: if (!root.hovered) root.active = false }

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
        target: AudioService
        function onVolumeChanged() { if (root.osdReady) root.show("volume", AudioService.muted ? "󰝟" : "󰕾", AudioService.volume) }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChanged() { if (root.osdReady) root.show("brightness", "󰃠", BrightnessService.brightness) }
    }
}