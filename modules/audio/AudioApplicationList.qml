import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.scrolling
import qs.core
import qs.services.audio

Item {
    id: root

    required property var rows
    readonly property real applicationRowHeight: 68

    function rowIndex(key) {
        for (let index = 0; index < stableRows.count; index++) {
            if (stableRows.get(index).key === key)
                return index;
        }
        return -1;
    }

    function reconcileRows() {
        const source = Array.isArray(rows) ? rows : [];
        for (let targetIndex = 0; targetIndex < source.length; targetIndex++) {
            const record = source[targetIndex];
            const key = String(record?.key || "row:" + targetIndex);
            let currentIndex = rowIndex(key);
            if (currentIndex < 0) {
                stableRows.insert(targetIndex, {
                    key: key,
                    record: record
                });
                currentIndex = targetIndex;
            } else if (currentIndex !== targetIndex) {
                stableRows.move(currentIndex, targetIndex, 1);
                currentIndex = targetIndex;
            }
            stableRows.setProperty(currentIndex, "record", record);
        }
        while (stableRows.count > source.length)
            stableRows.remove(stableRows.count - 1);
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
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
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

                AppIcon {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    Layout.alignment: Qt.AlignVCenter
                    name: row.displayName
                    icon: row.iconName
                    iconSize: 38
                }

                Text {
                    Layout.preferredWidth: 142
                    Layout.maximumWidth: 142
                    Layout.alignment: Qt.AlignVCenter
                    text: row.displayName
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    maximumLineCount: 1
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
}
