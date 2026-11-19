import QtQuick
import qs.components
import qs.core
import qs.services.bluetooth
import qs.services.controlcenter

FocusScope {
    id: root

    property string confirmForgetAddress: ""
    readonly property var devices: BluetoothService.devices

    focus: true

    Component.onCompleted: BluetoothService.setConsumer("control-center.bluetooth", true)
    Component.onDestruction: BluetoothService.setConsumer("control-center.bluetooth", false)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            ControlCenterService.close();
            event.accepted = true;
        }
    }

    Timer {
        id: forgetTimeout
        interval: 4000
        onTriggered: root.confirmForgetAddress = ""
    }

    IslandGlyph {
        id: titleGlyph
        x: Design.space20
        y: Design.space20
        width: 25
        height: 25
        name: "bluetooth"
        glyphColor: Theme.accent
    }

    Text {
        x: titleGlyph.x + titleGlyph.width + Design.space12
        anchors.verticalCenter: titleGlyph.verticalCenter
        text: "Bluetooth"
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: Design.typeDisplay
        font.weight: Font.DemiBold
    }

    GlyphButton {
        anchors.right: closeButton.left
        anchors.rightMargin: Design.space4
        y: Design.space12
        width: 40
        height: 40
        glyph: "search"
        glyphSize: 17
        enabled: BluetoothService.enabled
        accessibleName: "Scan for Bluetooth devices"
        onActivated: BluetoothService.scan()
    }

    GlyphButton {
        id: closeButton
        anchors.right: parent.right
        anchors.rightMargin: Design.space16
        y: Design.space12
        width: 40
        height: 40
        glyph: "close"
        glyphSize: 16
        accessibleName: "Close Bluetooth controls"
        onActivated: ControlCenterService.close()
    }

    Rectangle {
        id: powerCard
        x: Design.space20
        y: 70
        width: parent.width - Design.space20 * 2
        height: 96
        radius: Design.radiusGrouped
        color: Theme.fillSubtle
        border.color: Theme.separator

        IconMark {
            x: Design.space20
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 48
            glyph: "bluetooth"
            glyphSize: 25
            glyphColor: BluetoothService.enabled ? Theme.accent : Theme.textSecondary
        }

        Column {
            x: 84
            anchors.verticalCenter: parent.verticalCenter
            spacing: Design.space4

            Text {
                text: BluetoothService.available ? BluetoothService.enabled ? "Bluetooth is on" : "Bluetooth is off" : "Bluetooth unavailable"
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: Design.typeTitle
                font.weight: Font.DemiBold
            }

            Text {
                text: BluetoothService.adapter?.name || "No adapter"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
            }
        }

        RailActionPill {
            anchors.right: parent.right
            anchors.rightMargin: Design.space20
            anchors.verticalCenter: parent.verticalCenter
            width: 90
            label: BluetoothService.enabled ? "On" : "Off"
            highlighted: BluetoothService.enabled
            enabled: BluetoothService.available
            opacity: enabled ? 1 : 0.45
            onActivated: BluetoothService.setEnabled(!BluetoothService.enabled)
        }
    }

    Text {
        x: Design.space24
        y: powerCard.y + powerCard.height + Design.space20
        text: BluetoothService.scanning ? "SCANNING" : "DEVICES"
        color: BluetoothService.scanning ? Theme.accent : Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: Design.typeCaption
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
    }

    Rectangle {
        id: deviceCard
        x: Design.space20
        y: powerCard.y + powerCard.height + 42
        width: parent.width - Design.space20 * 2
        height: parent.height - y - Design.space20
        radius: Design.radiusGrouped
        color: Theme.fillSubtle
        border.color: Theme.separator
        clip: true

        Text {
            anchors.centerIn: parent
            visible: root.devices.length === 0
            text: BluetoothService.enabled ? BluetoothService.scanning ? "Looking for devices" : "No devices yet" : "Turn on Bluetooth to see devices"
            color: Theme.textTertiary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: Design.space12
            contentWidth: width
            contentHeight: deviceColumn.height
            clip: true
            visible: root.devices.length > 0

            Column {
                id: deviceColumn
                width: parent.width
                spacing: Design.space8

                Repeater {
                    model: root.devices

                    Rectangle {
                        id: deviceRow
                        required property var modelData
                        readonly property bool selected: BluetoothService.selectedAddress === modelData.address
                        width: deviceColumn.width
                        height: selected ? 124 : 62
                        radius: Design.radiusControl
                        color: selected ? Theme.fillSelected : Theme.fillQuiet
                        border.color: selected ? Theme.tintBorder(Theme.accent) : Theme.separator

                        Behavior on height {
                            enabled: !Design.reducedMotion
                            SpatialSpring {
                                phase: "morph"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: BluetoothService.selectDevice(deviceRow.modelData.address)
                        }

                        IconMark {
                            x: Design.space12
                            y: 11
                            width: 40
                            height: 40
                            glyph: deviceRow.modelData.icon?.includes("headset") || deviceRow.modelData.icon?.includes("headphones") ? "headphones" : deviceRow.modelData.icon?.includes("keyboard") ? "keyboard" : "bluetooth"
                            glyphSize: 21
                            glyphColor: deviceRow.modelData.connected ? Theme.accent : Theme.textSecondary
                        }

                        Text {
                            x: 64
                            y: 12
                            width: parent.width - x - Design.space16
                            text: deviceRow.modelData.name || deviceRow.modelData.deviceName || deviceRow.modelData.address
                            elide: Text.ElideRight
                            color: Theme.textPrimary
                            font.family: Design.fontText
                            font.pixelSize: Design.typeBody
                            font.weight: Font.DemiBold
                        }

                        Text {
                            x: 64
                            y: 32
                            text: deviceRow.modelData.pairing ? "Confirm on device" : deviceRow.modelData.connected ? "Connected" : deviceRow.modelData.paired ? "Paired" : deviceRow.modelData.trusted ? "Trusted" : "Available"
                            color: Theme.textSecondary
                            font.family: Design.fontText
                            font.pixelSize: Design.typeLabel
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: Design.space16
                            y: 33
                            visible: deviceRow.modelData.connected && deviceRow.modelData.batteryAvailable
                            text: Math.round(deviceRow.modelData.battery * 100) + "%"
                            color: Theme.accent
                            font.family: Design.fontMono
                            font.pixelSize: Design.typeLabel
                        }

                        Row {
                            x: Design.space12
                            y: 76
                            spacing: Design.space8
                            visible: deviceRow.selected

                            RailActionPill {
                                visible: deviceRow.modelData.pairing
                                label: "Cancel pairing"
                                onActivated: BluetoothService.cancelPairing()
                            }

                            RailActionPill {
                                visible: !deviceRow.modelData.pairing && !deviceRow.modelData.paired
                                label: "Pair"
                                highlighted: true
                                enabled: BluetoothService.enabled
                                opacity: enabled ? 1 : 0.4
                                onActivated: BluetoothService.pairSelected()
                            }

                            RailActionPill {
                                visible: !deviceRow.modelData.pairing && deviceRow.modelData.paired
                                label: deviceRow.modelData.connected ? "Disconnect" : "Connect"
                                highlighted: !deviceRow.modelData.connected
                                enabled: BluetoothService.enabled || deviceRow.modelData.connected
                                opacity: enabled ? 1 : 0.4
                                onActivated: deviceRow.modelData.connected ? BluetoothService.disconnectSelected() : BluetoothService.connectSelected()
                            }

                            RailActionPill {
                                visible: deviceRow.modelData.paired
                                label: deviceRow.modelData.trusted ? "Untrust" : "Trust"
                                onActivated: BluetoothService.setTrusted(!deviceRow.modelData.trusted)
                            }

                            RailActionPill {
                                visible: deviceRow.modelData.paired || deviceRow.modelData.trusted
                                label: root.confirmForgetAddress === deviceRow.modelData.address ? "Confirm forget" : "Forget"
                                destructive: root.confirmForgetAddress === deviceRow.modelData.address
                                onActivated: {
                                    if (root.confirmForgetAddress === deviceRow.modelData.address) {
                                        BluetoothService.forgetSelected();
                                        root.confirmForgetAddress = "";
                                    } else {
                                        root.confirmForgetAddress = deviceRow.modelData.address;
                                        forgetTimeout.restart();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
