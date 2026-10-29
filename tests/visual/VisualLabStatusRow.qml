import QtQuick

VisualLabInteractionFrame {
    id: root

    required property string title
    required property string detail
    property string state: "loading"
    property real progress: 0.42

    implicitHeight: 58
    toggleable: false
    controlRadius: 13
    controlInset: 3

    readonly property bool loading: state === "loading"
    readonly property bool ready: state === "ready"

    Item {
        id: stateWell

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 14
        }
        width: 30
        height: 30

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: root.loading ? "#18ff9f0a" : root.ready ? "#16ffffff" : "#0affffff"
        }

        VisualLabProgressRing {
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: root.loading
            running: root.loading && root.visible
        }

        VisualLabControlGlyph {
            anchors.centerIn: parent
            width: 15
            height: 15
            visible: !root.loading
            iconKind: root.ready ? "check" : "close"
            glyphColor: root.ready ? "#d8d8dc" : "#707078"
        }
    }

    Text {
        anchors {
            left: stateWell.right
            right: statusText.left
            top: parent.top
            leftMargin: 12
            rightMargin: 12
            topMargin: 10
        }
        text: root.title
        color: "#ededf0"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    Text {
        anchors {
            left: stateWell.right
            right: statusText.left
            bottom: parent.bottom
            leftMargin: 12
            rightMargin: 12
            bottomMargin: 9
        }
        text: root.detail
        color: "#74747c"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 9
    }

    Text {
        id: statusText

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 16
        }
        text: root.loading ? Math.round(root.progress * 100) + "%" : root.ready ? "READY" : "UNAVAILABLE"
        color: root.loading ? "#ffffaf32" : root.ready ? "#a8a8af" : "#66666e"
        font.family: "SF Pro Text"
        font.pixelSize: 9
        font.letterSpacing: root.loading ? 0 : 0.8
        font.weight: Font.DemiBold
    }

    Rectangle {
        anchors {
            left: stateWell.right
            right: statusText.left
            bottom: parent.bottom
            leftMargin: 12
            rightMargin: 12
            bottomMargin: 3
        }
        height: 1
        visible: root.loading
        color: "#10ffffff"

        Rectangle {
            width: parent.width * root.progress
            height: 1
            color: "#b8ff9f0a"

            Behavior on width {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
