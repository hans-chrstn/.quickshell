import QtQuick
import QtQuick.Controls

Popup {
    id: root

    required property var actions
    property int currentIndex: -1
    property Item returnFocusItem: null
    signal actionTriggered(string actionId)

    parent: Overlay.overlay
    modal: false
    focus: true
    padding: 6
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    implicitWidth: 214
    implicitHeight: menuColumn.implicitHeight + topPadding + bottomPadding
    transformOrigin: Item.TopRight

    onOpened: {
        currentIndex = firstEnabledIndex();
        Qt.callLater(() => menuColumn.forceActiveFocus());
    }
    onClosed: {
        currentIndex = -1;
        if (returnFocusItem)
            returnFocusItem.forceActiveFocus();
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 120
            }
            NumberAnimation {
                property: "scale"
                from: 0.965
                to: 1
                duration: 165
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 90
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.985
                duration: 90
                easing.type: Easing.OutCubic
            }
        }
    }

    background: Rectangle {
        radius: 15
        color: "#f21a1a1e"
        border.width: 1
        border.color: "#25ffffff"
    }

    contentItem: Column {
        id: menuColumn

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down) {
                root.moveSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Home) {
                root.currentIndex = root.firstEnabledIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                root.currentIndex = root.lastEnabledIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.trigger(root.currentIndex);
                event.accepted = true;
            }
        }

        Repeater {
            model: root.actions

            VisualLabMenuItem {
                required property int index
                required property var modelData

                width: menuColumn.width
                action: modelData
                highlighted: root.currentIndex === index
                onHovered: root.currentIndex = index
                onTriggered: root.trigger(index)
            }
        }
    }

    function firstEnabledIndex() {
        for (let index = 0; index < actions.length; ++index) {
            if (actions[index]?.enabled !== false)
                return index;
        }
        return -1;
    }

    function lastEnabledIndex() {
        for (let index = actions.length - 1; index >= 0; --index) {
            if (actions[index]?.enabled !== false)
                return index;
        }
        return -1;
    }

    function moveSelection(direction) {
        if (actions.length === 0)
            return;
        let index = currentIndex;
        for (let count = 0; count < actions.length; ++count) {
            index = (index + direction + actions.length) % actions.length;
            if (actions[index]?.enabled !== false) {
                currentIndex = index;
                return;
            }
        }
    }

    function trigger(index) {
        const action = actions[index];
        if (!action || action.enabled === false)
            return;
        close();
        actionTriggered(String(action.id || ""));
    }

    function openFor(sourceItem) {
        if (!sourceItem || !parent || actions.length === 0)
            return false;
        returnFocusItem = sourceItem;
        const point = sourceItem.mapToItem(parent, sourceItem.width, sourceItem.height + 8);
        x = Math.max(8, Math.min(point.x - implicitWidth, parent.width - implicitWidth - 8));
        y = Math.max(8, Math.min(point.y, parent.height - implicitHeight - 8));
        open();
        return true;
    }
}
