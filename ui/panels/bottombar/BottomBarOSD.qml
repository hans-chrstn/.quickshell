import QtQuick
import qs.core
import qs.ui.shared

ValueIndicatorPill {
    id: root
    
    width: ThemeManager.osdPillWidth
    height: ThemeManager.osdPillHeight
    
    property string osdScreenName: ""
    readonly property string screenName: osdScreenName !== "" ? osdScreenName : ((root.Window.window && root.Window.window.screen) ? root.Window.window.screen.name : "")
    
    displayType: OSDManager.currentType
    statusIcon: OSDManager.currentIcon
    indicatorValue: OSDManager.currentValue
    isPillActive: (OSDManager.active || hoverInteractionHandler.hovered) && (ViewManager.lastActiveScreenName === screenName)
    
    progressColor: displayType === "brightness" ? "#FFCC00" : ThemeManager.accentColor
    
    readonly property bool isHovered: hoverInteractionHandler.hovered

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
    }
}
