import QtQuick
import QtQuick.Controls
import qs.core
import qs.components.menus

Popup {
    id: root

    property var actions: []
    property int currentIndex: -1
    signal actionTriggered(string actionId)

    function firstEnabledIndex() {
        for (let index = 0; index < actions.length; ++index)
            if (actions[index]?.enabled !== false) return index
        return -1
    }

    function moveSelection(direction) {
        if (actions.length === 0) return
        let index = currentIndex
        for (let count = 0; count < actions.length; ++count) {
            index = (index + direction + actions.length) % actions.length
            if (actions[index]?.enabled !== false) {
                currentIndex = index
                return
            }
        }
    }

    function trigger(index) {
        const action = actions[index]
        if (!action || action.enabled === false) return
        close()
        actionTriggered(String(action.id || ""))
    }

    function openFor(sourceItem, localX, localY) {
        if (!sourceItem || !parent || actions.length === 0) return false
        const point = sourceItem.mapToItem(parent, localX, localY)
        currentIndex = firstEnabledIndex()
        x = Math.max(8, Math.min(point.x,
            parent.width - implicitWidth - 8))
        y = Math.max(8, Math.min(point.y,
            parent.height - implicitHeight - 8))
        open()
        return true
    }

    parent: Overlay.overlay
    modal: false
    focus: true
    padding: 6
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    implicitWidth: 172
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

    onClosed: currentIndex = -1
    onOpened: Qt.callLater(() => contentItem.forceActiveFocus())

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 110 }
            NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 130;
                easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90 }
            NumberAnimation { property: "scale"; from: 1; to: 0.985; duration: 90;
                easing.type: Easing.OutCubic }
        }
    }

    background: Rectangle {
        radius: 14
        color: Design.surfaceRaised
        border.width: 1
        border.color: Design.glassStroke
    }

    contentItem: Column {
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down) {
                root.moveSelection(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return
                    || event.key === Qt.Key_Enter
                    || event.key === Qt.Key_Space) {
                root.trigger(root.currentIndex)
                event.accepted = true
            }
        }

        Repeater {
            model: root.actions

            ContextMenuItem {
                required property var modelData
                required property int index
                width: parent.width
                action: modelData
                highlighted: root.currentIndex === index
                onHovered: root.currentIndex = index
                onTriggered: root.trigger(index)
            }
        }
    }
}
