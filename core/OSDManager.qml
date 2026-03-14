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
    property string currentMessage: ""
    property bool isPersistent: false

    property bool _isReady: false

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (!root.isPersistent) {
                root.active = false
            }
        }
    }

    function show(type, value, icon) {
        if (!root._isReady) return
        
        root.currentType = type
        root.isPersistent = (type === "chrono")
        
        if (type === "chrono") {
            root.currentMessage = value || ""
            root.currentIcon = icon || ThemeManager.iconClock
            root.currentValue = 0
        } else if (type === "message") {
            root.currentMessage = value || ""
            root.currentIcon = icon || ""
            root.currentValue = 0
        } else if (typeof value === "string" && icon === undefined) {
            root.currentType = "message"
            root.currentMessage = type
            root.currentIcon = value
            root.currentValue = 0
        } else {
            root.currentMessage = ""
            root.currentValue = value || 0
            root.currentIcon = icon || ""
        }
        
        root.active = true
        hideTimer.restart()
    }

    signal manuallyHidden(string type)

    function hide(type) {
        if (type === undefined || root.currentType === type) {
            root.isPersistent = false
            root.active = false
            hideTimer.stop()
        }
    }

    function manualHide(type) {
        if (type === undefined || root.currentType === type) {
            root.manuallyHidden(root.currentType)
            root.hide(type)
        }
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
