import QtQuick
import QtQuick.Controls
import qs.components
import qs.components.scrolling
import qs.core
import qs.services.audio
import "../../services/audio/AudioRouteModel.js" as AudioRouteModel

Item {
    id: root

    required property var application
    readonly property var rows: AudioRouteModel.routeRows(AudioService.applicationRouteTargets, AudioService.defaults?.output)
    readonly property string observedKey: AudioRouteModel.observedRouteKey(application, rows, AudioService.defaults?.output?.id)
    readonly property var routeState: AudioService.applicationRouteState
    readonly property bool routeBusy: routeState?.busy === true
    readonly property string pendingKey: routeBusy && routeState?.pendingGroupKey === application?.key ? String(routeState?.pendingTargetStableKey || "default") : ""
    property string selectedKey: ""

    function reconcileSelection() {
        selectedKey = AudioRouteModel.routeSelectionKey(rows, selectedKey.length > 0 ? selectedKey : observedKey, "retain");
    }

    function activate(key) {
        const row = rows.find(candidate => candidate.key === key);
        if (!row || row.available === false || routeBusy || application?.direction !== "output")
            return false;
        selectedKey = row.key;
        return AudioService.setApplicationRoute(application.key, row.targetStableKey).accepted === true;
    }

    function handleNavigation(key, modifiers) {
        if (key === Qt.Key_Up)
            selectedKey = AudioRouteModel.routeSelectionKey(rows, selectedKey, "previous");
        else if (key === Qt.Key_Down)
            selectedKey = AudioRouteModel.routeSelectionKey(rows, selectedKey, "next");
        else if (key === Qt.Key_Home)
            selectedKey = AudioRouteModel.routeSelectionKey(rows, selectedKey, "first");
        else if (key === Qt.Key_End)
            selectedKey = AudioRouteModel.routeSelectionKey(rows, selectedKey, "last");
        else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
            return activate(selectedKey);
        else
            return false;
        return true;
    }

    onRowsChanged: reconcileSelection()
    Component.onCompleted: reconcileSelection()

    ListView {
        id: routeList

        anchors.fill: parent
        anchors.rightMargin: 9
        visible: root.rows.length > 0
        clip: true
        model: root.rows
        spacing: 2
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MinimalScrollBar {}

        SmoothScrollBehavior {
            target: routeList
            wheelStep: 58
        }

        delegate: Item {
            id: row

            required property int index
            required property var modelData
            readonly property bool current: modelData.key === root.observedKey
            readonly property bool pending: modelData.key === root.pendingKey
            readonly property bool available: modelData.available !== false
            width: routeList.width
            height: 58

            HighlightableSurface {
                anchors.fill: parent
                interactive: row.available
                selected: row.current
                focused: row.modelData.key === root.selectedKey && !row.current
                hoverEnabled: row.available
                accentColor: Theme.textSecondary
                baseColor: "transparent"
                cornerRadius: 14
                accessibleName: row.modelData.displayName + (row.current ? ", current output" : "")
                onSurfaceActivated: {
                    root.selectedKey = row.modelData.key;
                    root.activate(row.modelData.key);
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 12
                color: row.current || row.pending ? Theme.fillStrong : Theme.fillSubtle

                IslandGlyph {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    name: row.modelData.key === "default" ? "repeat" : "volumeHigh"
                    glyphColor: !row.available ? Theme.textDisabled : row.current || row.pending ? Theme.textPrimary : Theme.textSecondary
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 60
                anchors.right: routeStatus.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: row.modelData.displayName
                    color: row.available ? Theme.textPrimary : Theme.textDisabled
                    font.family: Design.fontText
                    font.pixelSize: 13
                    font.weight: row.current ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: row.modelData.key === "default" && !row.available ? "No system output is currently available" : row.modelData.detail
                    color: Theme.textTertiary
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            Text {
                id: routeStatus
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: row.pending
                text: "Routing…"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 10
            }

            IslandGlyph {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                visible: row.current && !row.pending
                name: "checkmark"
                glyphColor: Theme.textPrimary
            }
        }
    }
}
