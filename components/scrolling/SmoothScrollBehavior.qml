import QtQuick

Item {
    id: root

    required property Flickable target
    property int orientation: Qt.Vertical
    property real wheelStep: 52
    property int wheelDuration: 150
    property bool enabled: true

    anchors.fill: parent
    z: 20

    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property real minimumPosition:
        horizontal ? target.originX : target.originY
    readonly property real maximumPosition: minimumPosition + Math.max(0,
        horizontal ? target.contentWidth - target.width
                   : target.contentHeight - target.height)
    readonly property real currentPosition:
        horizontal ? target.contentX : target.contentY
    property real destination: minimumPosition

    function bounded(value) {
        return Math.max(minimumPosition, Math.min(maximumPosition, value))
    }

    function cancel() {
        wheelAnimation.stop()
        destination = bounded(currentPosition)
    }

    function syncDestination() {
        if (!wheelAnimation.running)
            destination = bounded(currentPosition)
    }

    function scrollPixels(delta) {
        wheelAnimation.stop()
        const next = bounded(currentPosition - delta)
        const moved = Math.abs(next - currentPosition) > 0.01
        if (moved) {
            if (horizontal)
                target.contentX = next
            else
                target.contentY = next
        }
        destination = next
        return moved
    }

    function scrollSteps(delta) {
        const base = wheelAnimation.running
            ? destination : bounded(currentPosition)
        const next = bounded(base - delta / 120 * wheelStep)
        if (Math.abs(next - base) <= 0.01)
            return false

        destination = next
        wheelAnimation.restart()
        return true
    }

    onMinimumPositionChanged: destination = bounded(destination)
    onMaximumPositionChanged: destination = bounded(destination)

    Connections {
        target: root.target
        function onContentXChanged() { root.syncDestination() }
        function onContentYChanged() { root.syncDestination() }
    }

    NumberAnimation {
        id: wheelAnimation
        target: root.target
        property: root.horizontal ? "contentX" : "contentY"
        to: root.destination
        duration: root.wheelDuration
        easing.type: Easing.OutCubic
    }

    WheelHandler {
        target: null
        enabled: root.enabled && root.maximumPosition > root.minimumPosition
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const pixelDelta = root.horizontal
                ? (event.pixelDelta.x !== 0
                    ? event.pixelDelta.x : event.pixelDelta.y)
                : event.pixelDelta.y
            const angleDelta = root.horizontal
                ? (event.angleDelta.x !== 0
                    ? event.angleDelta.x : event.angleDelta.y)
                : event.angleDelta.y
            const moved = pixelDelta !== 0
                ? root.scrollPixels(pixelDelta)
                : root.scrollSteps(angleDelta)
            event.accepted = moved
        }
    }
}
