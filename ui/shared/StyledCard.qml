import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root

    property string title: ""
    property string icon: ""
    property alias content: contentArea.data
    property bool interactive: false

    property color backgroundColor: ThemeManager.surfaceSubtleColor
    property real cornerRadius: ThemeManager.globalCornerRadius

    signal clicked()

    implicitWidth: layout.implicitWidth + (Kirigami.Units.largeSpacing * 2)
    implicitHeight: layout.implicitHeight + (Kirigami.Units.largeSpacing * 2)

    Layout.fillWidth: true

    Rectangle {
        id: matteOuter
        anchors.fill: parent
        radius: root.cornerRadius
        color: "#1c1c1e"
        opacity: interactionHandler.hovered && root.interactive ? 0.9 : 0.7
        Behavior on opacity { NumberAnimation { duration: ThemeManager.durationFast } }
    }

    Rectangle {
        id: matteInner
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.cornerRadius - 1)
        color: "#101012"
        opacity: interactionHandler.hovered && root.interactive ? 0.95 : 0.75
        Behavior on opacity { NumberAnimation { duration: ThemeManager.durationFast } }
    }

    Rectangle {
        id: matteBorder
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.cornerRadius - 1)
        color: "transparent"
        border.color: ThemeManager.outlineStrongColor
        border.width: 1
    }

    layer.enabled: interactionHandler.hovered && root.interactive
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowOpacity: 0.2
        shadowBlur: 0.3
        shadowVerticalOffset: 2
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing + 4
        spacing: Kirigami.Units.mediumSpacing

        scale: interactionHandler.hovered && root.interactive ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutQuart } }

        RowLayout {
            id: headerArea
            Layout.fillWidth: true
            visible: root.title !== "" || root.icon !== ""
            spacing: Kirigami.Units.largeSpacing

            StyledLabel {
                text: root.icon
                type: "icon"
                visible: root.icon !== ""
                opacity: 0.7
            }

            Kirigami.Heading {
                text: root.title
                level: 4
                Layout.fillWidth: true
                color: ThemeManager.contentOnBackgroundColor
                font.family: ThemeManager.fontFamily
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: headerArea.visible && contentArea.children.length > 0
            opacity: 0.1
        }

        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    TapHandler {
        id: tapHandler
        enabled: root.interactive
        onTapped: root.clicked()
    }

    HoverHandler {
        id: interactionHandler
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }
}
