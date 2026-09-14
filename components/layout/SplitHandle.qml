import QtQuick
import qs.core

Item {
    id: root

    property bool vertical: false
    property bool highlighted: hover.hovered || drag.active
    signal dragStarted
    signal dragged(real delta)
    signal dragFinished

    implicitWidth: vertical ? 28 : 12
    implicitHeight: vertical ? 12 : 28

    Rectangle {
        anchors.centerIn: parent
        width: root.vertical ? 28 : 3
        height: root.vertical ? 3 : 28
        radius: 2
        color: root.highlighted ? Design.blue : Design.separator
        opacity: root.highlighted ? 0.9 : 0.55

        Behavior on color {
            ColorAnimation {
                duration: 110
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 110
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: root.vertical ? Qt.SplitVCursor : Qt.SplitHCursor
    }

    DragHandler {
        id: drag
        target: null
        acceptedButtons: Qt.LeftButton
        xAxis.enabled: !root.vertical
        yAxis.enabled: root.vertical
        onActiveChanged: {
            if (active)
                root.dragStarted();
            else
                root.dragFinished();
        }
        onActiveTranslationChanged: root.dragged(root.vertical ? activeTranslation.y : activeTranslation.x)
    }
}
