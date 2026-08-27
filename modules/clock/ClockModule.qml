import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    property QtObject context: null
    readonly property bool expanded: context?.expanded ?? false
    readonly property real expansionProgress: context?.expansionProgress ?? 0
    property date now: new Date()

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            text: Qt.formatDateTime(root.now, "hh:mm")
            color: Design.text
            font.family: Design.fontDisplay
            font.pixelSize: root.expanded ? 28 : 14
            font.weight: Font.DemiBold

            Behavior on font.pixelSize { NumberAnimation { duration: 220 } }
        }

        Item { Layout.fillWidth: true }

        ColumnLayout {
            visible: opacity > 0
            opacity: Math.max(0, Math.min(1,
                (root.expansionProgress - 0.55) / 0.45))
            spacing: 3

            transform: Translate {
                x: (1 - parent.opacity) * 10
            }

            Text {
                text: Qt.formatDateTime(root.now, "dddd")
                color: Design.text
                font.family: Design.fontDisplay
                font.pixelSize: 18
                font.weight: Font.Medium
            }

            Text {
                text: Qt.formatDateTime(root.now, "MMMM d, yyyy")
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 13
            }
        }
    }
}
