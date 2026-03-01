import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root

    property bool isExpanded: false
    property bool expandable: true
    property real collapsedWidth: 120
    property real expandedWidth: 120
    property real collapsedHeight: 28
    property real expandedHeight: 80
    property real pillRadius: 14

    property color pillColor: Qt.rgba(1, 1, 1, 0.08)
    property color pillBorderColor: Qt.rgba(1, 1, 1, 0.1)

    default property alias pillContent: contentLayout.data

    width: isExpanded ? expandedWidth : collapsedWidth
    height: isExpanded ? expandedHeight : collapsedHeight
    radius: pillRadius

    color: pillColor
    border.color: pillBorderColor
    border.width: 1

    z: isExpanded ? 100 : 1

    Behavior on width {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutExpo
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutExpo
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.expandable
        onClicked: {
            root.isExpanded = !root.isExpanded
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4
        clip: root.isExpanded
    }
}
