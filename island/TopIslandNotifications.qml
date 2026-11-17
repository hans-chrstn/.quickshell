import QtQuick
import qs.components
import qs.core
import qs.services.notifications

Item {
    id: root

    property bool expanded: false
    property var groups: NotificationService.historyGroups
    property bool dndActive: NotificationService.doNotDisturb
    property string expandedGroupKey: ""
    property string expandedNoticeId: ""
    readonly property int totalCount: groups.reduce((count, group) => count + group.count, 0)

    function toggleGroup(key) {
        expandedGroupKey = expandedGroupKey === key ? "" : key;
        expandedNoticeId = "";
    }

    function toggleNotice(id) {
        expandedNoticeId = expandedNoticeId === id ? "" : id;
    }

    Item {
        id: header
        x: Design.space16
        y: Design.space12
        width: parent.width - Design.space16 * 2
        height: 40

        Rectangle {
            visible: root.totalCount > 0
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(24, countText.implicitWidth + 12)
            height: 22
            radius: height / 2
            color: Theme.fillElevated

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.totalCount
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
            }
        }

        GlyphButton {
            anchors.right: clearButton.left
            anchors.rightMargin: Design.space4
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            glyph: root.dndActive ? "bellOff" : "bell"
            glyphSize: 16
            accessibleName: root.dndActive ? "Turn off do not disturb" : "Turn on do not disturb"
            primary: root.dndActive
            onActivated: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb)
        }

        GlyphButton {
            id: clearButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            glyph: "trash"
            glyphSize: 16
            accessibleName: "Clear notification history"
            enabled: NotificationService.history.length > 0
            onActivated: NotificationService.clearHistory()
        }
    }

    ListView {
        id: list
        x: Design.space16
        y: header.y + header.height + Design.space4
        width: parent.width - Design.space16 * 2
        height: Math.max(0, parent.height - y - Design.space12)
        clip: true
        spacing: Design.space8
        model: root.groups
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: Math.max(0, height)

        delegate: NotificationHistoryRow {
            required property var modelData
            width: list.width
            height: implicitHeight
            group: modelData
            expandedLayout: root.expanded
            groupExpanded: root.expandedGroupKey === group.key
            expandedNoticeId: root.expandedNoticeId
            onGroupRequested: key => root.toggleGroup(key)
            onNoticeRequested: id => root.toggleNotice(id)
            onRemoveRequested: id => NotificationService.removeHistory(id)
        }
    }

    IslandGlyph {
        visible: root.totalCount === 0
        anchors.centerIn: list
        width: 31
        height: 31
        name: "checkmark"
        glyphColor: Theme.accent
        Accessible.role: Accessible.Graphic
        Accessible.name: "No notifications"
    }
}
