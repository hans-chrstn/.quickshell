import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services
import qs.modules.bars
import qs.modules.island

BaseBar {
    id: root

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    anchors.top: true
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: FrameConfig.thickness
    color: "transparent"
    
    focusable: true
    WlrLayershell.keyboardFocus: appIsland.searchVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Item {
        id: islandHitbox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: appIsland.expanded ? FrameConfig.appIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth
        height: appIsland.expanded 
            ? (FrameConfig.appIslandExpandedHeight + FrameConfig.appIslandSearchBarHeight + 20)
            : FrameConfig.thickness
            
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    }

    mask: Region {
        Region { item: islandHitbox }
        Region { 
            item: (osdPill.active && osdPill.opacity > 0.1) ? osdPill : null
        }
    }

    Rectangle {
        id: barRect
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: FrameConfig.thickness
        color: FrameConfig.color
        z: 1
    }

    AppIsland {
        id: appIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 2
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color
    }

    ControlPill {
        id: osdPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: appIsland.height + 20
        z: 5
        width: 220; height: 44
        
        property string type: "volume"
        barColor: type === "brightness" ? "#FFCC00" : FrameConfig.accentColor
        
        readonly property bool hovered: hOsd.hovered
        onHoveredChanged: if (hovered) hideTimer.stop()
        else if (active) hideTimer.restart()

        HoverHandler { id: hOsd }

        onIconClicked: {
            if (type === "volume") {
                if (SystemControl.volume > 0) SystemControl.setVolume(0)
                else SystemControl.setVolume(SystemControl.lastVolume > 0 ? SystemControl.lastVolume : 0.5)
            }
        }
        
        onMoved: (val) => {
            if (type === "volume") SystemControl.setVolume(val)
            else SystemControl.setBrightness(val)
            hideTimer.restart() 
        }

        Timer { id: hideTimer; interval: 2000; onTriggered: if (!osdPill.hovered) osdPill.active = false }

        function show(newType, newIcon, newVal) {
            osdPill.type = newType
            osdPill.icon = newIcon
            osdPill.value = newVal
            osdPill.active = true
            hideTimer.restart()
        }
    }

    property bool osdReady: false
    Timer { interval: 1500; running: true; onTriggered: root.osdReady = true }

    Connections {
        target: SystemControl
        function onVolumeChanged() { if (root.osdReady) osdPill.show("volume", SystemControl.muted ? "󰝟" : "󰕾", SystemControl.volume) }
        function onBrightnessChanged() { if (root.osdReady) osdPill.show("brightness", "󰃠", SystemControl.brightness) }
    }

    MouseArea {
        anchors.fill: parent
        z: 1 
        enabled: appIsland.searchVisible
        onPressed: {
            appIsland.searchVisible = false
            appIsland.expanded = false
        }
    }

    MouseArea {
        id: triggerArea
        anchors.fill: islandHitbox
        z: 0
        hoverEnabled: true
        onEntered: { collapseTimer.stop(); appIsland.expanded = true }
        onExited: { if (!appIsland.searchVisible) collapseTimer.restart() }
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }

    Timer { id: collapseTimer; interval: 300; onTriggered: appIsland.expanded = false }
}
