import QtQuick
import QtQuick.Controls
import qs.core

ScrollBar {
    id: root

    policy: ScrollBar.AlwaysOn
    interactive: true
    hoverEnabled: true
    minimumSize: 0.08
    padding: 1
    property real displayOpacity: 0
    visible: size < 0.999
    opacity: 1

    function reveal() {
        fadeOut.stop()
        if (displayOpacity < 0.71 && !fadeIn.running)
            fadeIn.restart()
        idleTimer.restart()
    }

    onPositionChanged: {
        reveal()
    }

    onHoveredChanged: if (hovered) reveal()
    onPressedChanged: if (pressed) reveal()

    Timer {
        id: idleTimer
        interval: 1200
        onTriggered: if (!root.hovered && !root.pressed) fadeOut.restart()
    }

    background: Item {}

    contentItem: Rectangle {
        id: thumb
        implicitWidth: 3
        implicitHeight: 28
        radius: width / 2
        color: Design.text
        opacity: root.displayOpacity
    }

    NumberAnimation {
        id: fadeIn
        target: root
        property: "displayOpacity"
        to: 0.72
        duration: 120
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "displayOpacity"
        to: 0
        duration: 450
        easing.type: Easing.InOutCubic
    }
}
