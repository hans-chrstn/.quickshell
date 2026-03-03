import QtQuick
import qs.core
import qs.ui.shared

ValueIndicatorPill {
    id: root
    
    width: ThemeManager.osdPillWidth
    height: ThemeManager.osdPillHeight
    
    displayType: OSDManager.currentType
    statusIcon: OSDManager.currentIcon
    indicatorValue: OSDManager.currentValue
    isPillActive: OSDManager.active
    
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
