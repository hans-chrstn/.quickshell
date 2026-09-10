import QtQuick
import qs.services.time

Item {
    id: root

    required property string screenName
    property bool presented: false
    property bool expanded: false
    property real expansionProgress: 0
    property bool returningToClock: false
    readonly property var pages: ["power", "clock", "utilities", "power", "clock"]
    readonly property bool clockPresented: presented
        && (returningToClock || pages[pagesView.currentIndex] === "clock")
    readonly property string clockConsumerId:
        "island.clock." + screenName
    readonly property real collapsedImplicitWidth:
        pagesView.currentItem?.collapsedImplicitWidth ?? 0
    readonly property real collapsedImplicitHeight:
        pagesView.currentItem?.collapsedImplicitHeight ?? 0
    readonly property real expandedImplicitWidth:
        pagesView.currentItem?.expandedImplicitWidth ?? 0
    readonly property real expandedImplicitHeight:
        pagesView.currentItem?.expandedImplicitHeight ?? 0

    function updateClockConsumer() {
        ClockService.setConsumer(clockConsumerId, clockPresented)
    }

    onClockPresentedChanged: updateClockConsumer()
    onClockConsumerIdChanged: updateClockConsumer()
    Component.onCompleted: updateClockConsumer()
    Component.onDestruction:
        ClockService.setConsumer(clockConsumerId, false)

    function normalizeEdge() {
        if (pagesView.currentIndex === 0) {
            pagesView.currentIndex = 3
            pagesView.positionViewAtIndex(3, ListView.Beginning)
        } else if (pagesView.currentIndex === 4) {
            pagesView.currentIndex = 1
            pagesView.positionViewAtIndex(1, ListView.Beginning)
        }
    }

    function beginClockReturn() {
        wheelGuard.stop()
        returningToClock = pages[pagesView.currentIndex] !== "clock"
    }

    onExpandedChanged: if (!expanded) beginClockReturn()
    onExpansionProgressChanged: if (returningToClock
            && expansionProgress <= 0.001) {
        pagesView.currentIndex = 1
        pagesView.positionViewAtIndex(1, ListView.Beginning)
        returningToClock = false
    }

    function step(direction) {
        if (returningToClock || wheelGuard.running)
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

        pagesView.currentIndex = base + direction
    }

    Timer {
        id: wheelGuard
        interval: 180
    }

    ClockReturnLayer {
        anchors.fill: parent
        visible: root.returningToClock && root.presented
        progress: 1 - root.expansionProgress
    }

    ListView {
        id: pagesView
        anchors.fill: parent
        orientation: ListView.Horizontal
        model: root.pages
        currentIndex: 1
        clip: true
        interactive: !root.returningToClock
        opacity: root.returningToClock ? root.expansionProgress : 1
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
        onCurrentIndexChanged: root.updateClockConsumer()
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
