import QtQuick

Item {
    id: root

    property real progress: 0
    readonly property real boundedProgress: Math.max(0, Math.min(1,
        progress))

    opacity: boundedProgress

    ClockDateTimeView {
        anchors.fill: parent
        expansionProgress: 0
    }
}
