import QtQuick

Item {
    id: root

    required property Flickable target
    property real wheelStep: 52
    property int wheelDuration: 150
    property bool enabled: true

    anchors.fill: parent

    readonly property real minimumY: target.originY
    readonly property real maximumY: minimumY
        + Math.max(0, target.contentHeight - target.height)
    property real destinationY: minimumY

    function bounded(value) {
        return Math.max(minimumY, Math.min(maximumY, value))
    }

    function syncDestination() {
        if (!wheelAnimation.running)
            destinationY = bounded(target.contentY)
    }

    function scrollPixels(delta) {
        wheelAnimation.stop()
        const next = bounded(target.contentY - delta)
        const moved = Math.abs(next - target.contentY) > 0.01
        if (moved)
            target.contentY = next
        destinationY = next
        return moved
    }

    function scrollSteps(delta) {
        const base = wheelAnimation.running
            ? destinationY : bounded(target.contentY)
        const next = bounded(base - delta / 120 * wheelStep)
        if (Math.abs(next - base) <= 0.01)
            return false

        destinationY = next
        wheelAnimation.restart()
        return true
    }

    onMinimumYChanged: destinationY = bounded(destinationY)
    onMaximumYChanged: destinationY = bounded(destinationY)

    Connections {
        target: root.target
        function onContentYChanged() { root.syncDestination() }
    }

    NumberAnimation {
        id: wheelAnimation
        target: root.target
        property: "contentY"
        to: root.destinationY
        duration: root.wheelDuration
        easing.type: Easing.OutCubic
    }

    WheelHandler {
        target: null
        enabled: root.enabled && root.target.contentHeight > root.target.height
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const pixelY = event.pixelDelta.y
            const moved = pixelY !== 0
                ? root.scrollPixels(pixelY)
                : root.scrollSteps(event.angleDelta.y)
            event.accepted = moved
        }
    }
}
