import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: root
    
    property var modelData
    screen: modelData

    anchors {
        bottom: true
    }
    
    margins {
        bottom: FrameConfig.thickness + 20
    }
    
    implicitWidth: 220
    implicitHeight: 44
    
    color: "transparent"
    
    exclusionMode: pill.active ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: false
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "osd"

    property bool ready: false
    Timer {
        id: startupTimer
        interval: 1500
        running: true
        onTriggered: root.ready = true
    }

    ControlPill {
        id: pill
        anchors.fill: parent
        
        property string type: "volume"
        barColor: type === "brightness" ? "#FFCC00" : FrameConfig.accentColor
        
        readonly property bool hovered: hPill.hovered
        onHoveredChanged: if (hovered) hideTimer.stop()
        else if (active) hideTimer.restart()

        HoverHandler { id: hPill }

        onIconClicked: {
            if (type === "volume") {
                if (SystemControl.volume > 0) {
                    SystemControl.setVolume(0)
                } else {
                    SystemControl.setVolume(SystemControl.lastVolume > 0 ? SystemControl.lastVolume : 0.5)
                }
            }
        }
        
        onMoved: (val) => {
            if (type === "volume") SystemControl.setVolume(val)
            else SystemControl.setBrightness(val)
            hideTimer.restart() 
        }

        Timer {
            id: hideTimer
            interval: 2000
            onTriggered: if (!pill.hovered) pill.active = false
        }

        function show(newType, newIcon, newVal) {
            pill.type = newType
            pill.icon = newIcon
            pill.value = newVal
            pill.active = true
            hideTimer.restart()
        }
    }

    Connections {
        target: SystemControl
        function onVolumeChanged() {
            if (root.ready) pill.show("volume", SystemControl.muted ? "󰝟" : "󰕾", SystemControl.volume)
        }
        function onBrightnessChanged() {
            if (root.ready) pill.show("brightness", "󰃠", SystemControl.brightness)
        }
    }
}
