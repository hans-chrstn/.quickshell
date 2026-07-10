import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root

    property bool expanded: false
    property int collapsedHeight: 56
    property int expandedHeight: 280

    default property alias content: contentArea.data

    height: root.expanded ? root.expandedHeight : root.collapsedHeight

    Behavior on height {
        NumberAnimation {
            duration: ThemeManager.durationMedium
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#1c1c1e"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 13
        color: "#101012"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 13
        color: "transparent"
        border.color: root.expanded ? ThemeManager.accentColor : ThemeManager.outlineStrongColor
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: 6
        clip: true
    }
}
