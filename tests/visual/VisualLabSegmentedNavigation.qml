import QtQuick

FocusScope {
    id: root

    required property var pages
    property int currentIndex: 0
    property bool reducedMotion: false
    signal pageRequested(int index)

    implicitHeight: 36
    activeFocusOnTab: enabled

    readonly property real segmentWidth: width / Math.max(1, pages.length)

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#0affffff"
        border.width: 1
        border.color: "#12ffffff"
    }

    Rectangle {
        x: 3 + root.currentIndex * root.segmentWidth
        y: 3
        width: root.segmentWidth - 6
        height: parent.height - 6
        radius: 9
        color: "#19ffffff"
        border.width: 1
        border.color: "#10ffffff"

        Behavior on x {
            NumberAnimation {
                duration: root.reducedMotion ? 70 : 230
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
            }
        }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.pages

            delegate: Item {
                id: segment

                required property int index
                required property var modelData

                width: root.segmentWidth
                height: root.height

                readonly property bool selected: root.currentIndex === index

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 3
                    }
                    radius: 9
                    color: segmentHover.hovered && !segment.selected ? "#0affffff" : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: segment.selected ? "#f2f2f4" : segmentHover.hovered ? "#c2c2c8" : "#85858d"
                    font.family: "SF Pro Text"
                    font.pixelSize: 10
                    font.weight: segment.selected ? Font.DemiBold : Font.Medium

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                HoverHandler {
                    id: segmentHover
                }

                TapHandler {
                    onTapped: root.select(segment.index)
                }
            }
        }
    }

    Rectangle {
        anchors {
            fill: parent
            margins: -2
        }
        radius: 14
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: "#78ffffff"
        opacity: root.activeFocus ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }
    }

    Keys.onPressed: event => {
        let nextIndex = root.currentIndex;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up)
            nextIndex = (root.currentIndex - 1 + root.pages.length) % root.pages.length;
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down)
            nextIndex = (root.currentIndex + 1) % root.pages.length;
        else if (event.key === Qt.Key_Home)
            nextIndex = 0;
        else if (event.key === Qt.Key_End)
            nextIndex = root.pages.length - 1;
        else
            return;
        root.select(nextIndex);
        event.accepted = true;
    }

    function select(index) {
        const boundedIndex = Math.max(0, Math.min(pages.length - 1, index));
        forceActiveFocus();
        if (boundedIndex === currentIndex)
            return;
        currentIndex = boundedIndex;
        pageRequested(boundedIndex);
    }
}
