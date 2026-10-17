import QtQuick
import QtQuick.Controls
import qs.core

ToolTip {
    id: root

    delay: 500
    timeout: 3500
    padding: 8
    leftPadding: 10
    rightPadding: 10

    contentItem: Text {
        text: root.text
        color: Theme.textPrimary
        font.family: Design.fontText
        font.pixelSize: 10
    }

    background: Rectangle {
        radius: 9
        color: Theme.islandExpanded
        border.width: 1
        border.color: Theme.glassStroke
    }
}
