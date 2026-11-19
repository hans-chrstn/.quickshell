import QtQuick
import qs.components
import qs.core

Item {
    id: root

    opacity: 0
    transform: Translate {
        id: translate
        x: Design.reducedMotion ? 0 : 18
    }

    Component.onCompleted: entranceAnimation.start()

    ParallelAnimation {
        id: entranceAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Design.settingsRowEntrance
            easing.type: Easing.OutCubic
        }

        SpatialSpring {
            target: translate
            property: "x"
            to: 0
            phase: "enter"
        }
    }
}
