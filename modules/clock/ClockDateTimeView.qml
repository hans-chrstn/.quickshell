import QtQuick
import qs.core
import qs.services.time

Item {
    id: root

    property real expansionProgress: 0
    readonly property real progress: Math.max(0, Math.min(1, expansionProgress))
    readonly property real collapsedScale: 0.58
    readonly property real contentScale: collapsedScale + (1 - collapsedScale) * progress
    readonly property real dateRevealProgress: Math.max(0, Math.min(1, (progress - 0.16) / 0.68))
    readonly property real collapsedImplicitWidth: timeText.implicitWidth * collapsedScale
    readonly property real collapsedImplicitHeight: timeText.implicitHeight * collapsedScale
    readonly property real expandedImplicitWidth: contentStage.width
    readonly property real expandedImplicitHeight: contentStage.height

    Item {
        id: contentStage

        readonly property real contentGap: 22
        readonly property real dateSlideDistance: 10
        readonly property real expandedTimeX: divider.x + divider.width + contentGap
        readonly property real collapsedTimeX: (width - timeText.width) / 2

        anchors.centerIn: parent
        width: dateColumn.implicitWidth + contentGap + divider.width + contentGap + timeText.implicitWidth
        height: Math.max(dateColumn.implicitHeight, divider.height, timeText.implicitHeight)

        Column {
            id: dateColumn

            objectName: "clockDateColumn"
            anchors.verticalCenter: parent.verticalCenter
            x: -contentStage.dateSlideDistance * (1 - root.dateRevealProgress)
            spacing: 0
            opacity: root.dateRevealProgress

            Text {
                text: Qt.formatDateTime(ClockService.now, "dddd")
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 11
                font.capitalization: Font.Capitalize
            }

            Text {
                text: Qt.formatDateTime(ClockService.now, "d MMMM")
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.capitalization: Font.Capitalize
            }
        }

        Rectangle {
            id: divider

            objectName: "clockDateDivider"
            anchors.verticalCenter: parent.verticalCenter
            x: dateColumn.implicitWidth + contentStage.contentGap
            width: 1
            height: 28
            color: Theme.separator
            opacity: root.dateRevealProgress
        }

        Text {
            id: timeText

            objectName: "clockTimeText"
            anchors.verticalCenter: parent.verticalCenter
            x: contentStage.collapsedTimeX + (contentStage.expandedTimeX - contentStage.collapsedTimeX) * root.progress
            text: Qt.formatDateTime(ClockService.now, "hh:mm")
            color: Theme.textPrimary
            font.family: Design.fontDisplay
            font.pixelSize: 30
            font.weight: Font.Light
            scale: root.contentScale
            transformOrigin: Item.Center
        }
    }
}
