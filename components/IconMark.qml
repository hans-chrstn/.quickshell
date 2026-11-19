import QtQuick
import qs.core

Item {
    id: root

    required property string glyph
    property color glyphColor: Theme.textPrimary
    property real glyphSize: 24

    implicitWidth: 48
    implicitHeight: 48

    IslandGlyph {
        anchors.centerIn: parent
        width: root.glyphSize
        height: root.glyphSize
        name: root.glyph
        glyphColor: root.glyphColor
    }
}
