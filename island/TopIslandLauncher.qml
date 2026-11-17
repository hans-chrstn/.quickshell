import QtQuick
import qs.components
import qs.core
import qs.services.launcher

FocusScope {
    id: root

    property bool expanded: false
    property var actionResult: null
    property real actionY: 0
    readonly property var results: LauncherService.results
    readonly property var selectedResult: LauncherService.selectedIndex >= 0 && LauncherService.selectedIndex < results.length ? results[LauncherService.selectedIndex] : null

    focus: true

    function openActions(id, preferredY) {
        const result = results.find(entry => entry.id === id);
        if (!result || !result.actions?.length)
            return;
        actionResult = result;
        actionY = preferredY;
    }

    onResultsChanged: actionResult = null

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && actionResult) {
            actionResult = null;
            event.accepted = true;
        }
    }

    Rectangle {
        id: searchField
        x: Design.space16
        y: Design.space12
        width: parent.width - Design.space16 * 2
        height: Design.minimumTouchTarget
        radius: Design.radiusControl
        color: Theme.fillElevated
        border.color: Theme.separatorQuiet

        IslandGlyph {
            id: searchGlyph
            x: Design.space12
            anchors.verticalCenter: parent.verticalCenter
            width: 17
            height: 17
            name: "search"
            glyphColor: Theme.accent
        }

        Text {
            id: queryText
            x: searchGlyph.x + searchGlyph.width + Design.space12
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - Design.space12
            text: LauncherService.query || "Search apps"
            color: LauncherService.query ? Theme.textPrimary : Theme.textTertiary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Rectangle {
            visible: LauncherService.query.length > 0
            x: Math.min(queryText.x + queryText.contentWidth + Design.space2, parent.width - Design.space12)
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 17
            color: Theme.accent

            SequentialAnimation on opacity {
                running: parent.visible && !Design.reducedMotion
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.2
                    duration: Design.launcherCaretBlinkDuration
                }
                NumberAnimation {
                    to: 1
                    duration: Design.launcherCaretBlinkDuration
                }
            }
        }
    }

    ListView {
        id: resultList
        x: Design.space16
        y: searchField.y + searchField.height + Design.space8
        width: root.expanded && root.results.length > 0 ? Math.round((root.width - 44) * 0.51) : root.width - Design.space16 * 2
        height: Math.max(0, root.height - y - Design.space16)
        model: root.results
        spacing: Design.space6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: height
        currentIndex: LauncherService.selectedIndex

        delegate: LauncherResultRow {
            required property var modelData
            required property int index
            width: resultList.width
            height: implicitHeight
            result: modelData
            resultIndex: index
            selected: LauncherService.selectedIndex === index
            expandedLayout: root.expanded
            onActivated: id => LauncherService.executeResult(id)
            onActionsRequested: id => root.openActions(id, mapToItem(root, 0, height).y)
            onSelectionRequested: index => LauncherService.selectedIndex = index
        }
    }

    Connections {
        target: LauncherService
        function onSelectedIndexChanged() {
            if (LauncherService.selectedIndex >= 0)
                resultList.positionViewAtIndex(LauncherService.selectedIndex, ListView.Contain);
        }
    }

    Rectangle {
        id: detailCard
        visible: root.expanded && Boolean(root.selectedResult)
        x: resultList.x + resultList.width + Design.space12
        y: resultList.y
        width: root.width - x - Design.space16
        height: resultList.height
        radius: Design.radiusGrouped
        color: Theme.fillQuiet
        border.color: Theme.separatorQuiet
        clip: true

        AppIcon {
            id: detailIcon
            anchors.horizontalCenter: parent.horizontalCenter
            y: Design.space20
            name: root.selectedResult?.title || ""
            icon: root.selectedResult?.icon || ""
            iconSize: Design.launcherDetailIconSize
        }

        Text {
            id: detailTitle
            x: Design.space12
            y: detailIcon.y + detailIcon.height + Design.space12
            width: parent.width - Design.space24
            text: root.selectedResult?.title || ""
            color: Theme.textPrimary
            font.family: Design.fontDisplay
            font.pixelSize: Design.typeTitle
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            id: detailSubtitle
            x: Design.space12
            y: detailTitle.y + detailTitle.height + Design.space4
            width: parent.width - Design.space24
            text: root.selectedResult?.subtitle || ""
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            id: description
            visible: Boolean(text)
            x: Design.space16
            y: detailSubtitle.y + detailSubtitle.height + Design.space8
            width: parent.width - Design.space16 * 2
            text: root.selectedResult?.description || ""
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            wrapMode: Text.Wrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        GlyphButton {
            visible: root.selectedResult && root.selectedResult.actions.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - Design.space20
            width: Design.launcherPrimaryActionSize
            height: Design.launcherPrimaryActionSize
            glyph: "launch"
            glyphSize: 18
            accessibleName: "Launch " + (root.selectedResult?.title || "application")
            onActivated: LauncherService.executeResult(root.selectedResult.id)
        }

        Column {
            x: Design.space12
            y: parent.height - implicitHeight - Design.space12
            width: parent.width - Design.space24
            spacing: Design.space4

            Repeater {
                model: root.selectedResult?.actions?.slice(0, 2) || []

                Rectangle {
                    required property var modelData
                    width: parent.width
                    height: Design.launcherActionHeight
                    radius: Design.radiusControl
                    color: actionPointer.containsMouse ? Theme.fillElevated : Theme.fillSubtle

                    IslandGlyph {
                        x: Design.space12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        name: "launch"
                        glyphColor: Theme.accent
                    }

                    Text {
                        x: 37
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - Design.space8
                        text: modelData.name
                        color: Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        id: actionPointer
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LauncherService.executeAction(root.selectedResult.id, modelData.id)
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.name + " for " + root.selectedResult.title
                    }
                }
            }
        }
    }

    IslandGlyph {
        id: emptyGlyph
        visible: root.results.length === 0
        anchors.horizontalCenter: resultList.horizontalCenter
        y: resultList.y + Math.max(0, (resultList.height - 50) / 2)
        width: 29
        height: 29
        name: "search"
        glyphColor: Theme.textTertiary
    }

    Text {
        visible: root.results.length === 0
        anchors.horizontalCenter: resultList.horizontalCenter
        y: emptyGlyph.y + emptyGlyph.height + Design.space6
        text: LauncherService.query ? "No matching apps" : "No applications"
        color: Theme.textSecondary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
    }

    MouseArea {
        visible: Boolean(root.actionResult)
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.actionResult = null
    }

    LauncherActionMenu {
        id: actionMenu
        visible: Boolean(root.actionResult)
        result: root.actionResult || ({
                actions: []
            })
        x: root.width - width - Design.space16
        y: Math.max(Design.space8, Math.min(root.actionY, root.height - height - Design.space8))
        onActionSelected: (appId, actionId) => LauncherService.executeAction(appId, actionId)
    }
}
