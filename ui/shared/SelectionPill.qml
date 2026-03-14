import QtQuick
import qs.core

Rectangle {
    id: root

    property int animationDuration: 400
    property real animationOvershoot: 1.4
    
    radius: ThemeManager.globalCornerRadius
    color: ThemeManager.accentColor
    z: 0

    Behavior on x {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.animationOvershoot
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.animationOvershoot
        }
    }
    
    Behavior on width {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.animationOvershoot
        }
    }
    
    Behavior on height {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.animationOvershoot
        }
    }
}
