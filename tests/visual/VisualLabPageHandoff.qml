import QtQuick

Item {
    id: root

    default property list<Component> pages
    property int currentIndex: 0
    property bool reducedMotion: false
    property int displayedIndex: 0
    property int pendingIndex: 0
    property int direction: 1
    property real handoffProgress: 1

    onCurrentIndexChanged: beginHandoff(currentIndex)

    Repeater {
        model: root.pages.length

        delegate: Loader {
            required property int index

            anchors.fill: parent
            active: true
            sourceComponent: root.pages[index]
            visible: index === root.displayedIndex
            opacity: root.handoffProgress < 0.5 ? 1 - root.handoffProgress * 2 : (root.handoffProgress - 0.5) * 2
            x: root.handoffProgress < 0.5 ? -root.direction * root.handoffProgress * 18 : root.direction * (1 - root.handoffProgress) * 18
        }
    }

    SequentialAnimation {
        id: handoff

        NumberAnimation {
            target: root
            property: "handoffProgress"
            from: 0
            to: 0.5
            duration: root.reducedMotion ? 35 : 105
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: root.displayedIndex = root.pendingIndex
        }

        NumberAnimation {
            target: root
            property: "handoffProgress"
            from: 0.5
            to: 1
            duration: root.reducedMotion ? 45 : 175
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
        }
    }

    function beginHandoff(index) {
        const boundedIndex = Math.max(0, Math.min(pages.length - 1, index));
        if (boundedIndex === displayedIndex && !handoff.running)
            return;
        if (handoff.running) {
            handoff.stop();
            handoffProgress = 1;
        }
        direction = boundedIndex >= displayedIndex ? 1 : -1;
        pendingIndex = boundedIndex;
        handoffProgress = 0;
        handoff.restart();
    }
}
