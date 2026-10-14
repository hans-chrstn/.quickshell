import QtQuick
import qs.core

Item {
    id: root

    // Tool limitation: this valid default alias targets the child host.
    // qmllint disable unresolved-alias
    default property alias content: container.data
    // qmllint enable unresolved-alias

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
