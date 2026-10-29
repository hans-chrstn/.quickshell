import QtQuick

Item {
    id: root

    property real morphProgress: 0
    property int materialMode: 2
    property bool blurAvailable: true

    readonly property color envelopeColor: !blurAvailable ? "#fc0c0c10" : materialMode === 0 ? "#fc08080a" : materialMode === 1 ? "#c918191e" : Qt.rgba(0.035, 0.035, 0.045, 0.97 - 0.12 * morphProgress)
    readonly property color outlineColor: materialMode === 0 ? "#20ffffff" : materialMode === 1 ? "#38ffffff" : "#2cffffff"
    readonly property real depthOpacity: materialMode === 0 ? 0.18 : materialMode === 1 ? 0.5 : 0.28 + 0.16 * morphProgress

    Rectangle {
        anchors.fill: parent
        radius: 23 + 9 * root.morphProgress
        color: root.envelopeColor
        border.width: 1
        border.color: root.outlineColor
    }

    Rectangle {
        anchors {
            fill: parent
            margins: 1
        }
        radius: 22 + 9 * root.morphProgress
        color: "#0affffff"
        opacity: root.blurAvailable ? root.depthOpacity : 0.18
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 22 + 10 * root.morphProgress
            rightMargin: 22 + 10 * root.morphProgress
        }
        height: 1
        color: "#2effffff"
        opacity: root.materialMode === 0 ? 0.36 : 0.5 + 0.16 * root.morphProgress
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 26 + 12 * root.morphProgress
            rightMargin: 26 + 12 * root.morphProgress
        }
        height: 1
        color: "#72000000"
        opacity: 0.4 + 0.24 * root.morphProgress
    }
}
