import QtQuick
import qs.components
import qs.core
import qs.modules.settings
import qs.services.controlcenter
import qs.services.settings

FocusScope {
    id: root

    readonly property string screenName: ControlCenterService.targetScreenName || SettingsService.targetScreenName
    readonly property real sideWidth: Math.max(150, Math.min(184, width * 0.29))
    readonly property real contentX: Design.space20 + sideWidth + Design.space20
    readonly property var searchResults: SettingsService.searchResults
    readonly property bool searching: SettingsService.searchQuery.length > 0
    focus: true

    Keys.onPressed: event => {
        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_F) {
            searchInput.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            if (SettingsService.searchQuery.length > 0)
                SettingsService.searchQuery = "";
            else if (!SettingsService.back())
                ControlCenterService.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up && !searchInput.activeFocus) {
            SettingsService.selectedCategory = Math.max(0, SettingsService.selectedCategory - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down && !searchInput.activeFocus) {
            SettingsService.selectedCategory = Math.min(SettingsService.categories.length - 1, SettingsService.selectedCategory + 1);
            event.accepted = true;
        }
    }
    Keys.priority: Keys.AfterItem

    Text {
        x: Design.space20
        y: Design.space20
        text: "Settings"
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: Design.typeDisplay
        font.weight: Font.DemiBold
    }

    GlyphButton {
        anchors.right: parent.right
        anchors.rightMargin: Design.space16
        y: Design.space12
        width: 40
        height: 40
        glyph: "close"
        glyphSize: 16
        accessibleName: "Close settings"
        onActivated: ControlCenterService.close()
    }

    Rectangle {
        id: searchField
        x: Design.space20
        y: 70
        width: root.sideWidth
        height: 42
        radius: Design.radiusControl
        color: searchInput.activeFocus ? Theme.interactionSelected : Theme.fillSubtle
        border.color: searchInput.activeFocus ? Theme.tintBorder(Theme.accent) : Theme.separator

        IslandGlyph {
            x: Design.space12
            anchors.verticalCenter: parent.verticalCenter
            width: 17
            height: 17
            name: "search"
            glyphColor: searchInput.activeFocus ? Theme.accent : Theme.textSecondary
        }

        Text {
            x: 39
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: "Search"
            color: Theme.textTertiary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
        }

        TextInput {
            id: searchInput
            x: 39
            width: parent.width - x - Design.space8
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            selectionColor: Theme.tintStrong(Theme.accent)
            selectedTextColor: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            clip: true
            activeFocusOnTab: true
            onTextEdited: SettingsService.searchQuery = text
            Component.onCompleted: text = SettingsService.searchQuery

            Connections {
                target: SettingsService
                function onSearchQueryChanged() {
                    if (searchInput.text !== SettingsService.searchQuery)
                        searchInput.text = SettingsService.searchQuery;
                }
            }
        }

        TapHandler {
            onTapped: searchInput.forceActiveFocus()
        }
    }

    Rectangle {
        x: root.contentX - Design.space12
        y: 70
        width: 1
        height: parent.height - y - Design.space20
        color: Theme.separator
    }

    Flickable {
        id: categoryScroller
        x: Design.space20
        y: searchField.y + searchField.height + Design.space12
        width: root.sideWidth
        height: Math.max(0, parent.height - y - Design.space20)
        contentWidth: width
        contentHeight: categoryColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: categoryColumn
            width: parent.width
            spacing: Design.space6

            Repeater {
                model: SettingsService.categories

                HighlightableSurface {
                    id: categoryRow
                    required property int index
                    required property var modelData
                    readonly property int matchCount: root.searchResults.filter(result => result.categoryId === modelData.id).length
                    width: categoryColumn.width
                    height: 48
                    opacity: root.searching && matchCount === 0 ? 0.42 : 1
                    selected: index === SettingsService.selectedCategory
                    selectionFillEnabled: false
                    accentColor: Theme.accent
                    baseColor: "transparent"
                    outlineColor: "transparent"
                    cornerRadius: Design.radiusControl
                    accessibleName: modelData.title + " settings"
                    onSurfaceActivated: {
                        SettingsService.searchQuery = "";
                        SettingsService.selectedCategory = index;
                        SettingsService.clearPages();
                    }

                    Rectangle {
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: categoryRow.selected ? 26 : 8
                        radius: 1
                        color: Theme.accent
                        opacity: categoryRow.selected ? 1 : 0

                        Behavior on height {
                            SpatialSpring {
                                phase: "morph"
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Design.motionStateDuration
                            }
                        }
                    }

                    Text {
                        x: Design.space16
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - (root.searching ? 30 : Design.space4)
                        text: modelData.title
                        color: categoryRow.selected ? Theme.textPrimary : Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: categoryRow.selected ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: Design.motionStateDuration
                            }
                        }
                    }

                    Text {
                        visible: root.searching && categoryRow.matchCount > 0
                        anchors.right: parent.right
                        anchors.rightMargin: Design.space12
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(categoryRow.matchCount)
                        color: Theme.accent
                        font.family: Design.fontMono
                        font.pixelSize: Design.typeLabel
                    }
                }
            }
        }
    }

    Item {
        id: contentViewport
        x: root.contentX
        y: 70
        width: Math.max(0, parent.width - x - Design.space20)
        height: Math.max(0, parent.height - y - Design.space20)
        clip: true

        SettingsPageHost {
            anchors.fill: parent
            screenName: root.screenName
            pageActive: SettingsService.searchQuery.length === 0
            visible: pageActive
        }

        Item {
            anchors.fill: parent
            visible: SettingsService.searchQuery.length > 0

            Text {
                id: resultHeader
                x: Design.space4
                y: Design.space4
                text: "Results"
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: Design.typeTitle
                font.weight: Font.DemiBold
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Design.space8
                y: Design.space8
                text: String(root.searchResults.length)
                color: Theme.textTertiary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
            }

            ListView {
                id: resultList
                x: Design.space4
                y: resultHeader.y + resultHeader.height + Design.space16
                width: parent.width - Design.space8
                height: parent.height - y
                spacing: Design.space8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.searchResults

                delegate: HighlightableSurface {
                    required property var modelData
                    width: resultList.width
                    height: 62
                    baseColor: "transparent"
                    cornerRadius: Design.radiusControl
                    accessibleName: modelData.title + " in " + modelData.categoryTitle
                    onSurfaceActivated: {
                        SettingsService.openSearchResult(modelData.id);
                        root.forceActiveFocus();
                    }

                    Text {
                        x: Design.space16
                        y: Design.space12
                        width: parent.width - x - Design.space16
                        text: modelData.title
                        color: Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        x: Design.space16
                        y: 37
                        width: parent.width - x - Design.space16
                        text: modelData.categoryTitle + " · " + modelData.description
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeLabel
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: Design.space16
                        anchors.rightMargin: Design.space16
                        height: 1
                        color: Theme.separator
                    }
                }
            }

            Text {
                anchors.centerIn: resultList
                visible: root.searchResults.length === 0
                text: "No matching settings"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
            }
        }
    }
}
