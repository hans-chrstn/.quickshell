import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.menus
import qs.components.scrolling
import qs.core
import qs.services.audio
import "../../components/models/KeyedListReconciler.js" as KeyedListReconciler
import "../../services/audio/AudioApplicationModel.js" as AudioApplicationModel

Item {
    id: root

    required property var rows
    readonly property real applicationRowHeight: 68
    readonly property int selectedIndex: KeyedListReconciler.indexOf(stableRows, selectedKey)
    property string selectedKey: ""
    property var contextApplication: null
    signal applicationSelected(string groupKey)

    function reconcileRows() {
        KeyedListReconciler.reconcile(stableRows, rows, "key", "row:");
        selectedKey = AudioApplicationModel.applicationSelectionKey(rows, selectedKey, "retain");
    }

    function moveSelection(command) {
        selectedKey = AudioApplicationModel.applicationSelectionKey(rows, selectedKey, command);
        if (selectedIndex >= 0)
            applicationList.positionViewAtIndex(selectedIndex, ListView.Contain);
        return selectedKey.length > 0;
    }

    function activateSelection() {
        if (selectedKey.length === 0)
            return false;
        applicationSelected(selectedKey);
        return true;
    }

    function openApplicationMenu(application, sourceItem, x, y) {
        if (!application || !sourceItem)
            return false;
        selectedKey = String(application.key || "");
        contextApplication = application;
        const state = AudioService.applicationControlState(application);
        applicationMenu.actions = [
            {
                id: "details",
                label: "Show stream details"
            },
            {
                id: "toggle-mute",
                label: state?.muted ? "Unmute all streams" : "Mute all streams",
                enabled: state?.ready === true && state?.capabilities?.muteWrite === true
            }
        ];
        return applicationMenu.openFor(sourceItem, x, y);
    }

    function openSelectionMenu() {
        if (selectedIndex < 0)
            return false;
        const delegate = applicationList.itemAtIndex(selectedIndex);
        return delegate?.openContextMenu?.() === true;
    }

    function handleNavigation(key, modifiers) {
        if (key === Qt.Key_Down)
            return moveSelection("next");
        if (key === Qt.Key_Up)
            return moveSelection("previous");
        if (key === Qt.Key_Home)
            return moveSelection("first");
        if (key === Qt.Key_End)
            return moveSelection("last");
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
            return activateSelection();
        if (key === Qt.Key_Menu || key === Qt.Key_F10 && (modifiers & Qt.ShiftModifier))
            return openSelectionMenu();
        return false;
    }

    onRowsChanged: reconcileRows()
    Component.onCompleted: reconcileRows()

    ListModel {
        id: stableRows
        dynamicRoles: true
    }

    ListView {
        id: applicationList

        anchors.fill: parent
        anchors.rightMargin: 9
        clip: true
        model: stableRows
        currentIndex: root.selectedIndex
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        Accessible.name: "Active audio applications"
        Accessible.role: Accessible.List
        ScrollBar.vertical: MinimalScrollBar {}

        SmoothScrollBehavior {
            target: applicationList
            wheelStep: root.applicationRowHeight
        }

        delegate: Item {
            id: row

            required property int index
            required property string key
            required property var record
            readonly property bool application: record.kind === "application"
            readonly property bool section: record.kind === "section"
            readonly property string label: String(record.label ?? "")
            readonly property string displayName: String(record.displayName ?? "")
            readonly property string iconName: String(record.iconName ?? "")
            readonly property var applicationState: application ? AudioService.applicationControlState(record) : record
            readonly property bool controllable: applicationState?.ready === true && applicationState?.capabilities?.volumeWrite === true && applicationState?.capabilities?.muteWrite === true

            function openContextMenu() {
                if (!application)
                    return false;
                return root.openApplicationMenu(record, identitySurface, identitySurface.width / 2, identitySurface.height / 2);
            }

            width: applicationList.width
            height: section ? 30 : root.applicationRowHeight

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: row.section
                spacing: 7

                Text {
                    text: row.label
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    text: String(row.record.count ?? "")
                    color: Theme.textTertiary
                    font.family: Design.fontMono
                    font.pixelSize: 10
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                visible: row.application
                spacing: 12

                HighlightableSurface {
                    id: identitySurface

                    Layout.preferredWidth: 192
                    Layout.preferredHeight: 52
                    Layout.alignment: Qt.AlignVCenter
                    baseColor: "transparent"
                    cornerRadius: 12
                    selected: root.selectedKey === row.key
                    accessibleName: row.displayName + ", " + (row.record.section === "recording" ? "recording" : "playing") + ", " + (row.applicationState?.muted ? "muted" : Math.round(Number(row.applicationState?.volume) * 100) + " percent")
                    onActiveFocusChanged: if (activeFocus)
                        root.selectedKey = row.key
                    onSurfaceActivated: {
                        root.selectedKey = row.key;
                        root.applicationSelected(row.key);
                    }
                    onSurfaceContextRequested: (x, y) => root.openApplicationMenu(row.record, identitySurface, x, y)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 8
                        spacing: 10

                        AppIcon {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignVCenter
                            name: row.displayName
                            icon: row.iconName
                            iconSize: 38
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: row.displayName
                            color: Theme.textPrimary
                            font.family: Design.fontText
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        IslandGlyph {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            Layout.alignment: Qt.AlignVCenter
                            name: "chevronRight"
                            glyphColor: Theme.textTertiary
                        }
                    }
                }

                AudioLevelSlider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    Layout.alignment: Qt.AlignVCenter
                    enabled: row.controllable
                    from: 0
                    to: 1
                    value: Math.max(0, Math.min(1, Number(row.applicationState?.volume) || 0))
                    accentColor: row.applicationState?.muted ? Theme.textTertiary : Theme.textPrimary
                    Accessible.name: row.displayName + " sound level"
                    onLevelEdited: value => AudioService.setApplicationVolume(row.key, value)
                    onStepRequested: steps => AudioService.adjustApplicationVolume(row.key, steps)
                }

                GlyphButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    enabled: row.controllable
                    glyph: row.record.section === "recording" ? row.applicationState?.muted ? "microphoneMuted" : "microphone" : row.applicationState?.muted ? "volumeMuted" : "volumeHigh"
                    glyphSize: 19
                    primary: row.applicationState?.muted === true
                    accentColor: row.applicationState?.muted ? Theme.danger : Theme.textSecondary
                    accessibleName: (row.applicationState?.muted ? "Unmute " : "Mute ") + row.displayName
                    onActivated: AudioService.setApplicationMuted(row.key, !row.applicationState?.muted)
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 58
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                height: 1
                visible: row.application && row.index < stableRows.count - 1 && stableRows.get(row.index + 1).record?.kind === "application"
                color: Theme.separator
            }
        }
    }

    ContextMenu {
        id: applicationMenu

        onActionTriggered: actionId => {
            if (!root.contextApplication)
                return;
            const key = String(root.contextApplication.key || "");
            if (actionId === "details")
                root.applicationSelected(key);
            else if (actionId === "toggle-mute") {
                const state = AudioService.applicationControlState(root.contextApplication);
                AudioService.setApplicationMuted(key, !state?.muted);
            }
        }
    }
}
