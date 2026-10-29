import QtQuick

Item {
    id: root

    required property string title
    property string detail: ""
    property bool selected: false
    property string glyph: ""
    property bool grouped: false
    signal activated

    implicitHeight: 54

    readonly property bool hovered: hover.hovered

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.grouped ? 4 : 0
        radius: root.grouped ? 12 : 15
        color: tap.pressed ? "#20ffffff" : root.selected ? "#13ffffff" : root.hovered ? "#0dffffff" : root.grouped ? "transparent" : "#08ffffff"
        border.width: root.grouped ? 0 : root.selected ? 1 : 0
        border.color: root.selected ? "#30ffffff" : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: iconWell

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 12
        }
        width: 32
        height: 32
        radius: 11
        color: root.selected ? "#24ff9f0a" : "#0dffffff"

        Text {
            anchors.centerIn: parent
            text: root.glyph
            color: root.selected ? "#ffffaf32" : "#b8ffffff"
            font.family: "SF Pro Text"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }

    Text {
        anchors {
            left: iconWell.right
            right: status.left
            top: parent.top
            leftMargin: 12
            rightMargin: 10
            topMargin: root.detail.length > 0 ? 10 : 18
        }
        text: root.title
        color: "#f5f5f7"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 13
        font.weight: Font.Medium
    }

    Text {
        anchors {
            left: iconWell.right
            right: status.left
            bottom: parent.bottom
            leftMargin: 12
            rightMargin: 10
            bottomMargin: 9
        }
        visible: root.detail.length > 0
        text: root.detail
        color: "#84848b"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 10
    }

    Rectangle {
        id: status

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 15
        }
        width: 8
        height: 8
        radius: 4
        color: root.selected ? "#ffff9f0a" : "#32ffffff"
        scale: root.selected ? 1 : 0.72

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        id: tap

        onTapped: root.activated()
    }
}
