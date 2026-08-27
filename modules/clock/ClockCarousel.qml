import QtQuick

Item {
    id: root

    required property string screenName
    property bool expanded: false
    property real expansionProgress: 0
    readonly property var pages: ["power", "clock", "apps", "power", "clock"]

    function normalizeEdge() {
        if (pagesView.currentIndex === 0) {
            pagesView.currentIndex = 3
            pagesView.positionViewAtIndex(3, ListView.Beginning)
        } else if (pagesView.currentIndex === 4) {
            pagesView.currentIndex = 1
            pagesView.positionViewAtIndex(1, ListView.Beginning)
        }
    }

    function resetToClock() {
        wheelGuard.stop()
        pagesView.currentIndex = 1
        pagesView.positionViewAtIndex(1, ListView.Beginning)
    }

    onExpandedChanged: if (!expanded) resetToClock()

    function step(direction) {
        if (wheelGuard.running)
            return
        wheelGuard.restart()

        let base = pagesView.currentIndex
        if (base === 0) {
            base = 3
            pagesView.currentIndex = base
            pagesView.positionViewAtIndex(base, ListView.Beginning)
        } else if (base === root.pages.length - 1) {
            base = 1
            pagesView.currentIndex = base
            pagesView.positionViewAtIndex(base, ListView.Beginning)
        }

        const next = base + direction
        pagesView.currentIndex = next
    }

    Timer {
        id: wheelGuard
        interval: 180
    }

    ListView {
        id: pagesView
        anchors.fill: parent
        orientation: ListView.Horizontal
        model: root.pages
        currentIndex: 1
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600
        maximumFlickVelocity: width * 7
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: 0
        highlightMoveDuration: 260
        highlightMoveVelocity: -1

        delegate: ClockCarouselPage {
            required property int index
            required property string modelData
            width: pagesView.width
            height: pagesView.height
            page: modelData
            screenName: root.screenName
            expanded: root.expanded
            expansionProgress: root.expansionProgress
        }

        onMovementEnded: root.normalizeEdge()
        Component.onCompleted: positionViewAtIndex(1, ListView.Beginning)
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.x !== 0
                ? event.angleDelta.x : event.angleDelta.y
            if (delta !== 0)
                root.step(delta > 0 ? -1 : 1)
            event.accepted = true
        }
    }
}
