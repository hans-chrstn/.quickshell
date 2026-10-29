import QtQuick
import QtQuick.Controls
import qs.core
import qs.components.menus

Popup {
    id: root

    property var actions: []
    property int currentIndex: -1
    property Item returnFocusItem: null
    signal actionTriggered(string actionId)

    function firstEnabledIndex() {
        for (let index = 0; index < actions.length; ++index)
            if (actions[index]?.enabled !== false)
                return index;
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

    function lastEnabledIndex() {
        for (let index = actions.length - 1; index >= 0; --index)
            if (actions[index]?.enabled !== false)
                return index;
        return -1;
    }

    function trigger(index) {
        const action = actions[index];
        if (!action || action.enabled === false)
            return;
        close();
        actionTriggered(String(action.id || ""));
    }

    function openFor(sourceItem, localX, localY) {
        if (!sourceItem || !parent || actions.length === 0)
            return false;
        const anchorX = Number.isFinite(localX) ? localX : sourceItem.width;
        const anchorY = Number.isFinite(localY) ? localY : sourceItem.height + 8;
        const point = sourceItem.mapToItem(parent, anchorX, anchorY);
        returnFocusItem = sourceItem;
        currentIndex = firstEnabledIndex();
        x = Math.max(8, Math.min(point.x, parent.width - implicitWidth - 8));
        y = Math.max(8, Math.min(point.y, parent.height - implicitHeight - 8));
        open();
        return true;
    }

    parent: Overlay.overlay
    modal: false
    focus: true
    padding: 6
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    implicitWidth: 214
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    transformOrigin: Item.TopRight

    onClosed: {
        currentIndex = -1;
        if (returnFocusItem)
            returnFocusItem.forceActiveFocus();
        returnFocusItem = null;
    }
    onOpened: {
        currentIndex = firstEnabledIndex();
        Qt.callLater(() => contentItem.forceActiveFocus());
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Design.motionStateDuration
            }
            NumberAnimation {
                property: "scale"
                from: 0.965
                to: 1
                duration: Design.motionControlDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Design.motionControlCurve
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Design.motionPressDuration
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.985
                duration: Design.motionPressDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    background: Rectangle {
        radius: 15
        color: Theme.surfaceRaised
        border.width: 1
        border.color: Theme.separatorStrong
    }

    contentItem: Column {
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
