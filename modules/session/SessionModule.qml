import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services.session

Item {
    id: root

    property QtObject context: null
    readonly property real expansionProgress: context?.expansionProgress ?? 0

    focus: true
    Component.onCompleted: focusRetrier.startFocus()

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: SessionService
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            SessionService.moveSelection(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left
                   || event.key === Qt.Key_Backtab) {
            SessionService.moveSelection(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                   || event.key === Qt.Key_Space) {
            SessionService.choose(SessionService.selectedIndex)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            SessionService.close()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            Text {
                text: "Session"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            Text {
                text: SessionService.confirmingIndex >= 0
                    ? "Select again to confirm" : "Esc to cancel"
                color: SessionService.confirmingIndex >= 0
                    ? Design.red : Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Repeater {
                model: SessionService.actions

                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    required property int index

                    readonly property bool selected:
                        index === SessionService.selectedIndex
                    readonly property bool confirming:
                        index === SessionService.confirmingIndex

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: confirming ? Qt.rgba(1, 0.27, 0.23, 0.18)
                        : (selected ? Design.surfaceRaised : Design.surface)
                    border.width: selected ? 1 : 0
                    border.color: confirming ? Design.red : Design.blue

                    Behavior on color { ColorAnimation { duration: 130 } }

                    HoverHandler {
                        onHoveredChanged: if (hovered) {
                            SessionService.selectedIndex = tile.index
                            if (SessionService.confirmingIndex !== tile.index)
                                SessionService.confirmingIndex = -1
                        }
                    }

                    TapHandler {
                        onTapped: SessionService.choose(tile.index)
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.symbol
                            color: tile.confirming ? Design.red
                                : tile.modelData.color
                            font.family: Design.fontDisplay
                            font.pixelSize: 30
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.confirming ? "Are you sure?"
                                : tile.modelData.title
                            color: tile.confirming ? Design.red : Design.text
                            font.family: Design.fontText
                            font.pixelSize: 12
                            font.weight: tile.selected
                                ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
