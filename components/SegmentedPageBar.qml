import QtQuick
import qs.core

FocusScope {
    id: root

    required property var pages
    required property string currentPage
    property color accentColor: Theme.selection
    property real controlHeight: 32
    property real cornerRadius: 10
    property real labelPixelSize: 10
    property bool reducedMotion: false
    signal pageSelected(string pageId)

    readonly property int currentIndex: pageIndex(currentPage)
    readonly property real segmentWidth: width / Math.max(1, pages.length)

    implicitHeight: controlHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.PageTabList
    Accessible.name: "Page navigation"

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Theme.surfaceGrouped
        border.width: 1
        border.color: Theme.separatorQuiet
    }

    Rectangle {
        x: 3 + Math.max(0, root.currentIndex) * root.segmentWidth
        y: 3
        width: Math.max(0, root.segmentWidth - 6)
        height: Math.max(0, root.height - 6)
        radius: Math.max(6, root.cornerRadius - 3)
        color: Theme.interactionSelected
        border.width: 1
        border.color: Theme.separator
        visible: root.pages.length > 0 && root.currentIndex >= 0

        Behavior on x {
            NumberAnimation {
                duration: root.reducedMotion ? 70 : Design.motionTravelDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Design.motionControlCurve
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: root.reducedMotion ? 70 : Design.motionTravelDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.pages

            Item {
                id: segment

                required property int index
                required property var modelData

                readonly property bool selected: root.currentIndex === index
                readonly property bool available: modelData.enabled === undefined || modelData.enabled

                width: root.segmentWidth
                height: root.height
                opacity: available ? 1 : 0.38

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 3
                    }
                    radius: Math.max(6, root.cornerRadius - 3)
                    color: segmentHover.hovered && !segment.selected && segment.available ? Theme.interactionHover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Design.motionStateDuration
                            easing.type: Design.motionStandardEasing
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: segment.selected ? Theme.textPrimary : segmentHover.hovered && segment.available ? Theme.textSecondary : Theme.textTertiary
                    font.family: Design.fontText
                    font.pixelSize: root.labelPixelSize
                    font.weight: segment.selected ? Font.DemiBold : Font.Medium

                    Behavior on color {
                        ColorAnimation {
                            duration: Design.motionStateDuration
                            easing.type: Design.motionStandardEasing
                        }
                    }
                }

                HoverHandler {
                    id: segmentHover

                    enabled: segment.available
                }

                TapHandler {
                    enabled: root.enabled && segment.available
                    onTapped: root.selectIndex(segment.index)
                }
            }
        }
    }

    Rectangle {
        anchors {
            fill: parent
            margins: -2
        }
        radius: root.cornerRadius + 2
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.focusRing
        opacity: root.activeFocus ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    Keys.onPressed: event => {
        if (root.pages.length === 0)
            return;
        let nextIndex = root.currentIndex >= 0 ? root.currentIndex : 0;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up)
            nextIndex = root.nextAvailableIndex(nextIndex, -1);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down)
            nextIndex = root.nextAvailableIndex(nextIndex, 1);
        else if (event.key === Qt.Key_Home)
            nextIndex = root.firstAvailableIndex();
        else if (event.key === Qt.Key_End)
            nextIndex = root.lastAvailableIndex();
        else
            return;
        root.selectIndex(nextIndex);
        event.accepted = true;
    }

    function pageIndex(pageId) {
        const requested = String(pageId || "");
        for (let index = 0; index < pages.length; ++index) {
            if (String(pages[index].id) === requested)
                return index;
        }
        return -1;
    }

    function isAvailable(index) {
        if (index < 0 || index >= pages.length)
            return false;
        return pages[index].enabled === undefined || pages[index].enabled;
    }

    function nextAvailableIndex(origin, direction) {
        for (let offset = 1; offset <= pages.length; ++offset) {
            const index = (origin + direction * offset + pages.length) % pages.length;
            if (isAvailable(index))
                return index;
        }
        return origin;
    }

    function firstAvailableIndex() {
        for (let index = 0; index < pages.length; ++index) {
            if (isAvailable(index))
                return index;
        }
        return currentIndex;
    }

    function lastAvailableIndex() {
        for (let index = pages.length - 1; index >= 0; --index) {
            if (isAvailable(index))
                return index;
        }
        return currentIndex;
    }

    function selectIndex(index) {
        if (!enabled || !isAvailable(index))
            return;
        forceActiveFocus();
        const pageId = String(pages[index].id);
        if (pageId === currentPage)
            return;
        pageSelected(pageId);
    }
}
