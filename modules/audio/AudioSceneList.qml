import QtQuick
import QtQuick.Controls
import qs.components
import qs.components.menus
import qs.components.scrolling
import qs.core
import "../../services/audio/AudioScenePresentationModel.js" as AudioScenePresentationModel

Item {
    id: root

    required property var scenes
    property string selectedSceneId: ""
    property string busySceneId: ""
    property string resultSceneId: ""
    property string resultCode: ""
    signal sceneRequested(string sceneId)
    signal removeRequested(string sceneId, string sceneName)
    signal selectionRequested(string sceneId)

    readonly property var rows: AudioScenePresentationModel.rows(scenes)
    readonly property real rowHeight: 66
    property var contextRow: null

    function moveSelection(step) {
        const sceneId = AudioScenePresentationModel.movedSelection(rows, selectedSceneId, step);
        if (sceneId.length === 0)
            return false;
        selectionRequested(sceneId);
        const index = AudioScenePresentationModel.indexForId(rows, sceneId);
        if (index >= 0)
            sceneList.positionViewAtIndex(index, ListView.Contain);
        return true;
    }

    function selectBoundary(last) {
        if (rows.length === 0)
            return false;
        const index = last ? rows.length - 1 : 0;
        selectionRequested(rows[index].id);
        sceneList.positionViewAtIndex(index, ListView.Contain);
        return true;
    }

    function activateSelected() {
        if (AudioScenePresentationModel.indexForId(rows, selectedSceneId) < 0)
            return false;
        sceneRequested(selectedSceneId);
        return true;
    }

    function removeSelected() {
        const index = AudioScenePresentationModel.indexForId(rows, selectedSceneId);
        if (index < 0)
            return false;
        removeRequested(rows[index].id, rows[index].name);
        return true;
    }

    Text {
        anchors.centerIn: parent
        visible: root.rows.length === 0
        text: "Save the current sound setup as a scene"
        color: Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: 11
    }

    ListView {
        id: sceneList

        anchors.fill: parent
        anchors.rightMargin: 9
        visible: root.rows.length > 0
        clip: true
        model: root.rows
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        ScrollBar.vertical: MinimalScrollBar {}

        SmoothScrollBehavior {
            target: sceneList
            wheelStep: root.rowHeight
        }

        delegate: Item {
            id: row

            required property int index
            required property var modelData
            readonly property bool selected: root.selectedSceneId === modelData.id
            readonly property bool busy: root.busySceneId === modelData.id
            readonly property bool hasResult: root.resultSceneId === modelData.id && root.resultCode.length > 0
            readonly property string statusText: busy ? "Applying…" : !hasResult ? "" : root.resultCode === "confirmed" ? "Applied" : root.resultCode === "unchanged" ? "Current" : "Failed"

            width: sceneList.width
            height: root.rowHeight

            HighlightableSurface {
                anchors.fill: parent
                selected: row.selected
                focused: row.busy
                interactive: !root.busySceneId.length
                contextEnabled: !row.busy
                hoverEnabled: !root.busySceneId.length
                accentColor: Theme.textSecondary
                baseColor: "transparent"
                cornerRadius: 15
                accessibleName: row.modelData.name + ", " + row.modelData.summary
                onSurfaceActivated: {
                    root.selectionRequested(row.modelData.id);
                    root.sceneRequested(row.modelData.id);
                }
                onSurfaceContextRequested: (x, y) => {
                    root.contextRow = row.modelData;
                    sceneMenu.openFor(row, x, y);
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 42
                radius: 13
                color: row.selected || row.busy ? Theme.fillStrong : Theme.fillSubtle

                IslandGlyph {
                    anchors.centerIn: parent
                    width: 23
                    height: 23
                    name: row.busy ? "repeat" : "volumeHigh"
                    glyphColor: row.selected || row.busy ? Theme.textPrimary : Theme.textSecondary
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 62
                anchors.right: status.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: row.modelData.name
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: 14
                    font.weight: row.selected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: row.modelData.summary
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            Text {
                id: status

                anchors.right: actionIcon.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: row.statusText
                color: row.statusText === "Failed" ? Theme.danger : Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 10
            }

            IslandGlyph {
                id: actionIcon

                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                name: row.statusText === "Applied" || row.statusText === "Current" ? "checkmark" : "play"
                glyphColor: Theme.textSecondary
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 62
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                visible: row.index < root.rows.length - 1
                color: Theme.separator
                opacity: 0.56
            }
        }
    }

    ContextMenu {
        id: sceneMenu

        actions: [
            {
                id: "remove",
                label: "Remove scene",
                destructive: true
            }
        ]
        onActionTriggered: actionId => {
            if (actionId === "remove" && root.contextRow)
                root.removeRequested(root.contextRow.id, root.contextRow.name);
        }
    }
}
