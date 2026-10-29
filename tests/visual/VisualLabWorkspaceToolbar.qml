import QtQuick

Item {
    id: root

    readonly property var modes: [
        {
            "label": "Edit"
        },
        {
            "label": "Preview"
        }
    ]

    Rectangle {
        id: identityMark

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 14
        }
        width: 30
        height: 30
        radius: 10
        color: "#16ffffff"

        VisualLabControlGlyph {
            anchors.centerIn: parent
            width: 15
            height: 15
            iconKind: "diamond"
            glyphColor: "#ffffaf32"
        }
    }

    Text {
        anchors {
            left: identityMark.right
            verticalCenter: parent.verticalCenter
            leftMargin: 10
        }
        text: "Wallpaper Studio"
        color: "#efeff1"
        font.family: "SF Pro Text"
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    VisualLabSegmentedNavigation {
        anchors.centerIn: parent
        width: 190
        height: 32
        pages: root.modes
    }

    Row {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 10
        }
        spacing: 2

        VisualLabGlyphButton {
            width: 36
            height: 36
            toggleable: false
            iconKind: "plus"
        }

        VisualLabGlyphButton {
            width: 36
            height: 36
            toggleable: false
            iconKind: "more"
        }
    }
}
