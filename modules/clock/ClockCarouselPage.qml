import QtQuick
import qs.core
import qs.components
import qs.services.launcher
import qs.services.session

Item {
    id: root

    required property string page
    required property string screenName
    property bool expanded: false
    property real expansionProgress: 0
    property date now: new Date()

    Timer {
        interval: 1000
        running: root.visible && root.page === "clock"
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        anchors.centerIn: parent
        visible: root.page === "clock"
        text: Qt.formatDateTime(root.now, "hh:mm")
        color: Design.text
        font.family: Design.fontDisplay
        font.pixelSize: 14 + 10 * root.expansionProgress
        font.weight: root.expanded ? Font.Light : Font.Medium
    }

    Row {
        anchors.centerIn: parent
        visible: root.page !== "clock"
        spacing: 7

        IslandGlyph {
            anchors.verticalCenter: parent.verticalCenter
            name: root.page
            glyphColor: actionHover.hovered ? Design.text : Design.textMuted
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.page === "apps" ? "Apps" : "Power"
            color: actionHover.hovered ? Design.text : Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 12 + root.expansionProgress
            font.weight: Font.Medium
        }
    }

    HoverHandler { id: actionHover }

    TapHandler {
        enabled: root.page !== "clock"
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        grabPermissions: PointerHandler.ApprovesTakeOverByAnything
        onTapped: {
            if (root.page === "apps")
                LauncherService.open("", root.screenName)
            else
                SessionService.open(root.screenName)
        }
    }
}
