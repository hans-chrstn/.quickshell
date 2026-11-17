import QtQuick
import qs.components
import qs.core

Item {
    id: root

    required property var result
    required property int resultIndex
    property bool selected: false
    property bool expandedLayout: false
    readonly property bool actionsAvailable: result.actions?.length > 0
    property real reveal: 0

    signal activated(string id)
    signal actionsRequested(string id)
    signal selectionRequested(int index)

    implicitHeight: Design.launcherRowHeight
    opacity: reveal
    scale: Design.launcherResultEnterScale + (1 - Design.launcherResultEnterScale) * reveal
    transformOrigin: Item.Left

    Component.onCompleted: revealTimer.start()

    Timer {
        id: revealTimer
        interval: Design.launcherResultStagger * Math.min(root.resultIndex, 5)
        onTriggered: root.reveal = 1
    }

    Behavior on reveal {
        enabled: !Design.reducedMotion
        NumberAnimation {
            duration: Design.launcherResultFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Design.radiusControl
        color: root.selected ? Theme.fillSelected : rowPointer.containsMouse ? Theme.fillElevated : Theme.fillQuiet
        border.color: root.selected ? Theme.tintBorder(Theme.accent) : Theme.separatorQuiet

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
            }
        }
    }

    Rectangle {
        visible: root.selected
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - Design.space16
        radius: width / 2
        color: Theme.accent
    }

    AppIcon {
        id: appIcon
        x: Design.space12
        anchors.verticalCenter: parent.verticalCenter
        name: root.result.title || ""
        icon: root.result.icon || ""
        iconSize: 28
    }

    Text {
        id: appTitle
        x: appIcon.x + appIcon.width + Design.space12
        y: root.expandedLayout && root.result.subtitle ? 7 : (parent.height - height) / 2
        width: parent.width - x - (root.actionsAvailable ? 41 : Design.space12)
        text: root.result.title || ""
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: Design.typeBody
        font.weight: root.selected ? Font.DemiBold : Font.Medium
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }

    Text {
        visible: root.expandedLayout && Boolean(root.result.subtitle)
        x: appTitle.x
        y: 26
        width: appTitle.width
        text: root.result.subtitle || ""
        color: Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: Design.typeCaption
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }

    MouseArea {
        id: rowPointer
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.selectionRequested(root.resultIndex)
        onClicked: root.activated(root.result.id)
        Accessible.role: Accessible.Button
        Accessible.name: "Launch " + (root.result.title || "application")
    }

    Item {
        visible: root.actionsAvailable
        x: appIcon.x - 5
        y: appIcon.y - 5
        width: appIcon.width + 10
        height: appIcon.height + 10

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actionsRequested(root.result.id)
            Accessible.role: Accessible.Button
            Accessible.name: "Actions for " + root.result.title
        }
    }

    IslandGlyph {
        visible: root.actionsAvailable
        x: parent.width - width - Design.space12
        anchors.verticalCenter: parent.verticalCenter
        width: 17
        height: 17
        name: "more"
        glyphColor: Theme.textTertiary
    }
}
