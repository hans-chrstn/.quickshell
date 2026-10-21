import QtQuick
import qs.core
import qs.services.audio
import "../../services/audio/AudioApplicationModel.js" as AudioApplicationModel

Item {
    id: root

    property string selectedGroupKey: ""
    readonly property var rows: AudioApplicationModel.listRows(AudioService.applications)
    readonly property var selectedApplication: AudioApplicationModel.applicationByKey(AudioService.applications, selectedGroupKey)

    implicitWidth: 600
    implicitHeight: 300

    function handleEscape() {
        if (selectedGroupKey.length === 0)
            return false;
        if (applicationDetail.handleEscape())
            return true;
        selectedGroupKey = "";
        return true;
    }

    function handleNavigation(key, modifiers) {
        if (selectedGroupKey.length > 0)
            return applicationDetail.handleNavigation(key, modifiers);
        return applicationList.handleNavigation(key, modifiers);
    }

    onRowsChanged: selectionReconcile.restart()

    Timer {
        id: selectionReconcile

        interval: 0
        onTriggered: {
            if (!root.selectedApplication && root.selectedGroupKey.length > 0)
                root.selectedGroupKey = "";
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Theme.fillSubtle
        border.width: 1
        border.color: Theme.separatorQuiet

        Text {
            anchors.centerIn: parent
            visible: root.rows.length === 0
            text: AudioService.inventoryLoaded ? "No active audio applications" : "Discovering applications…"
            color: Theme.textTertiary
            font.family: Design.fontText
            font.pixelSize: 11
        }

        AudioApplicationList {
            id: applicationList

            anchors.fill: parent
            anchors.margins: 12
            visible: opacity > 0
            enabled: root.selectedGroupKey.length === 0
            opacity: root.selectedGroupKey.length === 0 && root.rows.length > 0 ? 1 : 0
            rows: root.rows
            onApplicationSelected: groupKey => root.selectedGroupKey = groupKey

            Behavior on opacity {
                NumberAnimation {
                    duration: Design.contentRevealDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        AudioApplicationDetail {
            id: applicationDetail
            anchors.fill: parent
            visible: opacity > 0
            enabled: root.selectedApplication !== null
            opacity: root.selectedApplication !== null ? 1 : 0
            application: root.selectedApplication || ({})
            onBackRequested: root.selectedGroupKey = ""

            Behavior on opacity {
                NumberAnimation {
                    duration: Design.contentRevealDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
