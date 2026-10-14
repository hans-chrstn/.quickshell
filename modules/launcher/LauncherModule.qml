import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.components
import qs.components.scrolling
import qs.services.launcher

Item {
    id: root

    property QtObject context: null
    readonly property bool expanded: context?.expanded ?? false
    readonly property real expansionProgress: context?.expansionProgress ?? 0
    readonly property int measuredResultRows: Math.min(6, LauncherService.results.length)
    readonly property real collapsedImplicitWidth: 160
    readonly property real collapsedImplicitHeight: 22
    readonly property real expandedImplicitWidth: searchRow.implicitWidth
    readonly property real expandedImplicitHeight: searchHeader.implicitHeight + contentColumn.spacing + divider.implicitHeight + contentColumn.spacing + Math.max(96, measuredResultRows * 50)

    focus: true

    Component.onCompleted: focusRetrier.startFocus()

    FocusRetrier {
        id: focusRetrier
        targetItem: searchInput
        activeService: LauncherService
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 10
        Item {
            id: searchHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            implicitHeight: 42

            RowLayout {
                id: searchRow
                anchors.fill: parent
                spacing: 12

                Text {
                    text: "⌕"
                    color: Design.textMuted
                    font.family: Design.fontDisplay
                    font.pixelSize: 24
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.preferredWidth: Math.max(360, searchPlaceholder.implicitWidth)
                    color: Design.text
                    selectionColor: Design.blue
                    font.family: Design.fontText
                    font.pixelSize: 19
                    clip: true
                    focus: true
                    text: LauncherService.query

                    onTextEdited: LauncherService.query = text
                    onAccepted: LauncherService.executeSelected()

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Down) {
                            smoothScroll.cancel();
                            LauncherService.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            smoothScroll.cancel();
                            LauncherService.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            LauncherService.close();
                            event.accepted = true;
                        }
                    }

                    Text {
                        id: searchPlaceholder
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: searchInput.text.length === 0
                        text: "Search applications"
                        color: Design.textMuted
                        opacity: 0.62
                        font: searchInput.font
                    }
                }

                Text {
                    text: LauncherService.results.length + " apps"
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            id: divider
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            implicitHeight: 1
            color: Design.separator
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SmoothScrollBehavior {
                id: smoothScroll
                target: resultsList
            }

            ScrollEdgeFeedback {
                target: resultsList
            }

            ListView {
                id: resultsList
                anchors.fill: parent
                clip: true
                spacing: 2
                model: LauncherService.results
                currentIndex: LauncherService.selectedIndex
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                ScrollBar.vertical: MinimalScrollBar {}

                delegate: HighlightableSurface {
                    id: row
                    required property var modelData
                    required property int index

                    width: Math.max(0, ListView.view.width - 10)
                    height: 48
                    interactive: false
                    focused: hover.hovered
                    selected: index === LauncherService.selectedIndex
                    baseColor: "transparent"
                    cornerRadius: 11

                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered)
                            LauncherService.selectedIndex = row.index
                    }

                    TapHandler {
                        onTapped: {
                            LauncherService.selectedIndex = row.index;
                            LauncherService.executeSelected();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 12

                        AppIcon {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            name: row.modelData.title
                            icon: row.modelData.icon
                            iconSize: 28
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.title
                                color: Design.text
                                font.family: Design.fontText
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.subtitle
                                color: Design.textMuted
                                font.family: Design.fontText
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            visible: row.index === LauncherService.selectedIndex
                            text: "↵"
                            color: Design.textMuted
                            font.family: Design.fontText
                            font.pixelSize: 13
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: LauncherService.results.length === 0
                    text: "No applications found"
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 13
                }
            }
        }
    }
}
