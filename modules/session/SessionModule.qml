import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services.session

Item {
    id: root

    property QtObject context: null
    readonly property real expansionProgress: context?.expansionProgress ?? 0
    readonly property real collapsedImplicitWidth: headerRow.implicitWidth
    readonly property real collapsedImplicitHeight: headerRow.implicitHeight
    readonly property real expandedImplicitWidth: Math.max(headerRow.implicitWidth, actionsRow.implicitWidth)
    readonly property real expandedImplicitHeight: headerRow.implicitHeight + contentColumn.spacing + actionsRow.implicitHeight

    focus: true
    Component.onCompleted: focusRetrier.startFocus()

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: SessionService
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            SessionService.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            SessionService.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            SessionService.choose(SessionService.selectedIndex);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            SessionService.close();
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 10

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            Text {
                text: "Session"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 11
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: SessionService.confirmingIndex >= 0 ? "Select again to confirm" : "Esc to cancel"
                color: SessionService.confirmingIndex >= 0 ? Design.red : Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }
        }

        RowLayout {
            id: actionsRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Repeater {
                model: SessionService.actions

                delegate: HighlightableSurface {
                    id: tile
                    required property var modelData
                    required property int index

                    readonly property bool keyboardSelected: index === SessionService.selectedIndex
                    readonly property bool confirming: index === SessionService.confirmingIndex
                    implicitWidth: Math.max(132, tileContent.implicitWidth + 16)
                    implicitHeight: Math.max(126, tileContent.implicitHeight + 20)

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    interactive: true
                    focused: hover.hovered
                    selected: tile.keyboardSelected || tile.confirming
                    accentColor: tile.confirming ? Design.red : Design.blue
                    baseColor: Design.surface
                    cornerRadius: 14
                    accessibleName: tile.modelData.title

                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered) {
                            SessionService.selectedIndex = tile.index;
                            if (SessionService.confirmingIndex !== tile.index)
                                SessionService.confirmingIndex = -1;
                        }
                    }

                    onSurfaceActivated: SessionService.choose(tile.index)

                    ColumnLayout {
                        id: tileContent
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.symbol
                            color: tile.confirming ? Design.red : tile.modelData.color
                            font.family: Design.fontDisplay
                            font.pixelSize: 30
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.confirming ? "Are you sure?" : tile.modelData.title
                            color: tile.confirming ? Design.red : Design.text
                            font.family: Design.fontText
                            font.pixelSize: 12
                            font.weight: tile.keyboardSelected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
