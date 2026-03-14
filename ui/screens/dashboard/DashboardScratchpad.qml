import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import "./scratchpad"

ColumnLayout {
    id: root

    property bool active: false

    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    StyledLabel {
        text: "Scratchpad"
        type: "heading"
        font.pixelSize: 28
    }

    ScratchpadEditor {
        active: root.active
    }

    Item { 
        Layout.fillHeight: true 
    }
}
