import QtQuick

VisualLabInteractionFrame {
    id: root

    required property string title
    property string detail: ""
    property string iconKind: "diamond"
    property string trailingIcon: selected ? "check" : "chevron"

    implicitHeight: 58
    controlRadius: 13
    controlInset: 3

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
        color: root.selected ? "#1fff9f0a" : "#0bffffff"

        VisualLabControlGlyph {
            anchors.centerIn: parent
            width: 16
            height: 16
            iconKind: root.iconKind
            glyphColor: root.semanticRole === "neutral" ? root.selected ? "#ffffaf32" : "#b8b8be" : root.semanticColor
        }
    }

    Text {
        anchors {
            left: iconWell.right
            right: trailingGlyph.left
            top: parent.top
            leftMargin: 12
            rightMargin: 10
            topMargin: root.detail.length > 0 ? 10 : 19
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
            left: iconWell.right
            right: trailingGlyph.left
            bottom: parent.bottom
            leftMargin: 12
            rightMargin: 10
            bottomMargin: 9
        }
        text: root.detail
        color: "#77777f"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 9
    }

    VisualLabControlGlyph {
        id: trailingGlyph

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 16
        }
        width: 16
        height: 16
        iconKind: root.trailingIcon
        glyphColor: root.selected ? "#ffffa21a" : "#74747c"
    }
}
