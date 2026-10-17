import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.menus
import qs.components.scrolling
import qs.core
import qs.services.audio
import "../../services/audio/AudioDeviceModel.js" as AudioDeviceModel

Item {
    id: root

    required property string role
    required property string title
    required property string glyph
    required property color accentColor
    readonly property var devices: AudioDeviceModel.devicesForRole(AudioService.nodes, role)
    readonly property string domainRole: role === "input-device" ? "input" : "output"
    readonly property var selection: domainRole === "input" ? AudioService.inputDeviceSelection : AudioService.outputDeviceSelection
    readonly property int cycleCandidateCount: AudioDeviceModel.cycleCandidates(AudioService.nodes, role).length
    readonly property real rowHeight: 68
    property var contextDevice: null

    function isRequested(device) {
        return String(selection?.requestedStableKey || "") === String(device?.stableKey || "") && selection?.phase !== "idle";
    }

    function rowStatus(device) {
        if (!device?.ready)
            return "Unavailable";
        if (device?.isDefault)
            return "Current";
        if (isRequested(device)) {
            if (selection.phase === "requested")
                return "Switching…";
            if (selection.phase === "preferred")
                return "Preferred";
            if (selection.phase === "failed" || selection.phase === "superseded")
                return "Failed";
        }
        return device?.isPreferredDefault ? "Preferred" : "";
    }

    function requestDevice(device) {
        return AudioService.setPreferredDevice(domainRole, String(device?.stableKey || ""));
    }

    function openDeviceMenu(device, sourceItem, x, y) {
        contextDevice = device;
        deviceMenu.actions = [
            {
                id: "rename",
                label: AudioService.deviceAlias(device?.stableKey).length > 0 ? "Edit name" : "Rename"
            },
            {
                id: "clear-alias",
                label: "Restore hardware name",
                enabled: AudioService.deviceAlias(device?.stableKey).length > 0
            }
        ];
        return deviceMenu.openFor(sourceItem, x, y);
    }

    implicitHeight: 296

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.preferredHeight: 42
            spacing: 11

            IslandGlyph {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                name: root.glyph
                glyphColor: root.accentColor
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                text: root.devices.length + (root.devices.length === 1 ? " device" : " devices")
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 11
            }

            GlyphButton {
                visible: root.domainRole === "output"
                enabled: root.cycleCandidateCount > 1
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                glyph: "repeat"
                glyphSize: 17
                accessibleName: "Use next output device"
                toolTip: enabled ? "Use next output" : "No other output available"
                onActivated: AudioService.cycleOutput(1)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: root.devices.length === 0
                text: AudioService.inventoryLoaded ? "No " + root.title.toLowerCase() : "Discovering…"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 12
            }

            ListView {
                id: deviceList
                anchors.fill: parent
                anchors.rightMargin: 9
                visible: root.devices.length > 0
                clip: true
                model: root.devices
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                ScrollBar.vertical: MinimalScrollBar {}

                SmoothScrollBehavior {
                    target: deviceList
                    wheelStep: root.rowHeight
                }

                delegate: Item {
                    id: row
                    required property int index
                    required property var modelData
                    readonly property int channelCount: Array.isArray(modelData.channels) ? modelData.channels.length : 0
                    width: deviceList.width
                    height: root.rowHeight
                    readonly property bool requested: root.isRequested(modelData)
                    readonly property string statusText: root.rowStatus(modelData)
                    readonly property bool selectable: modelData.ready && modelData.capabilities?.preferredDefaultWrite === true
                    readonly property string displayName: AudioService.deviceDisplayName(modelData)
                    readonly property string alias: AudioService.deviceAlias(modelData.stableKey)
                    Accessible.name: displayName + ", " + (statusText.length > 0 ? statusText : AudioDeviceModel.statusLabel(modelData))

                    HighlightableSurface {
                        anchors.fill: parent
                        selected: row.modelData.isDefault
                        focused: row.requested && !row.modelData.isDefault
                        interactive: row.selectable
                        contextEnabled: row.modelData.ready
                        hoverEnabled: row.selectable
                        accentColor: Theme.textSecondary
                        baseColor: "transparent"
                        cornerRadius: 15
                        accessibleName: row.displayName + ", " + (row.statusText.length > 0 ? row.statusText : AudioDeviceModel.statusLabel(row.modelData))
                        onSurfaceActivated: root.requestDevice(row.modelData)
                        onSurfaceContextRequested: (x, y) => root.openDeviceMenu(row.modelData, row, x, y)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        radius: 13
                        color: row.modelData.isDefault || row.requested ? Theme.tintStrong(root.accentColor) : Theme.tintSubtle(root.accentColor)

                        IslandGlyph {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            name: root.glyph
                            glyphColor: row.modelData.isDefault || row.requested ? root.accentColor : Theme.textSecondary
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 64
                        anchors.right: status.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            width: parent.width
                            text: row.displayName
                            color: row.modelData.ready ? Theme.textPrimary : Theme.textSecondary
                            font.family: Design.fontText
                            font.pixelSize: 14
                            font.weight: row.modelData.isDefault ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: row.alias.length > 0 ? row.modelData.displayName : (row.modelData.deviceApi.length > 0 ? row.modelData.deviceApi.toUpperCase() : "Audio device") + (row.channelCount > 0 ? " · " + row.channelCount + (row.channelCount === 1 ? " channel" : " channels") : "")
                            color: Theme.textSecondary
                            font.family: Design.fontText
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        id: status
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !row.modelData.isDefault && row.statusText.length > 0
                        text: row.statusText
                        color: row.statusText === "Failed" ? Theme.danger : row.requested ? root.accentColor : Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: 11
                    }

                    IslandGlyph {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        visible: row.modelData.isDefault
                        name: "checkmark"
                        glyphColor: root.accentColor
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 64
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        visible: !row.modelData.isDefault && row.index < root.devices.length - 1
                        color: Theme.separator
                        opacity: 0.56
                    }
                }
            }
        }
    }

    ContextMenu {
        id: deviceMenu

        onActionTriggered: actionId => {
            if (!root.contextDevice)
                return;
            if (actionId === "rename")
                Qt.callLater(aliasDialog.openWith, AudioService.deviceAlias(root.contextDevice.stableKey));
            else if (actionId === "clear-alias")
                AudioService.setDeviceAlias(root.contextDevice.stableKey, "");
        }
    }

    TextEntryDialog {
        id: aliasDialog
        title: "Name this device"
        message: root.contextDevice ? "Use a short name for “" + root.contextDevice.displayName + "”. Leave it blank to restore the hardware name." : ""
        fieldLabel: "Device name"
        placeholderText: root.contextDevice?.displayName || "Audio device"
        maximumLength: 64
        submitHandler: value => root.contextDevice ? AudioService.setDeviceAlias(root.contextDevice.stableKey, value) : ({
                    accepted: false,
                    message: "The audio device is no longer available."
                })
    }
}
