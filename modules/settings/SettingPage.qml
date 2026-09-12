import QtQuick
import qs.core

Item {
    id: root

    default property alias content: container.data

    opacity: 0
    transform: Translate {
        id: translate
        x: 12
    }

    Component.onCompleted: entranceAnimation.start()

    ParallelAnimation {
        id: entranceAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Design.contentRevealDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: translate
            property: "x"
            to: 0
            duration: Design.contentRevealDuration
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: container
        anchors.fill: parent
    }
}
