import QtQuick
import qs.components
import qs.core

Rectangle {
    id: root

    required property var device
    property bool selected: false
    property bool bluetoothEnabled: false
    property bool confirmForget: false
    signal selectionRequested(string address)
    signal pairRequested
    signal pairingCancelRequested
    signal connectRequested
    signal disconnectRequested
    signal trustRequested(bool trusted)
    signal forgetRequested

    height: selected ? 124 : 62
    activeFocusOnTab: true
    radius: Design.radiusControl
    color: selected ? Theme.fillSelected : Theme.fillQuiet
    border.color: selected ? Theme.tintBorder(Theme.accent) : Theme.separator
    clip: true

    Behavior on height {
        enabled: !Design.reducedMotion
        SpatialSpring {
            phase: "morph"
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 62
        onClicked: root.selectionRequested(String(root.device.address || ""))
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.selectionRequested(String(root.device.address || ""));
            event.accepted = true;
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: (root.device.name || root.device.deviceName || root.device.address) + ", " + (root.device.connected ? "Connected" : root.device.paired ? "Paired" : "Available")

    IconMark {
        x: Design.space12
        y: 11
        width: 40
        height: 40
        glyph: root.device.icon?.includes("headset") || root.device.icon?.includes("headphones") ? "headphones" : root.device.icon?.includes("keyboard") ? "keyboard" : "bluetooth"
        glyphSize: 21
        glyphColor: root.device.connected ? Theme.accent : Theme.textSecondary
    }

    Text {
        x: 64
        y: 12
        width: parent.width - x - Design.space16
        text: root.device.name || root.device.deviceName || root.device.address
        elide: Text.ElideRight
        color: Theme.textPrimary
        font.family: Design.fontText
        font.pixelSize: Design.typeBody
        font.weight: Font.DemiBold
    }

    Text {
        x: 64
        y: 32
        text: root.device.pairing ? "Confirm on device" : root.device.connected ? "Connected" : root.device.paired ? "Paired" : root.device.trusted ? "Trusted" : "Available"
        color: Theme.textSecondary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Design.space16
        y: 33
        visible: root.device.connected && root.device.batteryAvailable
        text: Math.round(root.device.battery * 100) + "%"
        color: Theme.accent
        font.family: Design.fontMono
        font.pixelSize: Design.typeLabel
    }

    Row {
        id: actions
        x: Design.space12
        y: root.height - height - Design.space12
        height: Design.minimumTouchTarget
        spacing: Design.space8
        visible: root.selected
        opacity: Math.max(0, Math.min(1, (root.height - 110) / 14))
        enabled: opacity > 0.95

        RailActionPill {
            objectName: "bluetooth-cancel-pairing"
            visible: root.device.pairing
            label: "Cancel pairing"
            onActivated: root.pairingCancelRequested()
        }

        RailActionPill {
            objectName: "bluetooth-pair"
            visible: !root.device.pairing && !root.device.paired
            label: "Pair"
            highlighted: true
            enabled: root.bluetoothEnabled
            onActivated: root.pairRequested()
        }

        RailActionPill {
            objectName: "bluetooth-connect"
            visible: !root.device.pairing && root.device.paired
            label: root.device.connected ? "Disconnect" : "Connect"
            highlighted: !root.device.connected
            enabled: root.bluetoothEnabled || root.device.connected
            onActivated: root.device.connected ? root.disconnectRequested() : root.connectRequested()
        }

        RailActionPill {
            objectName: "bluetooth-trust"
            visible: root.device.paired
            label: root.device.trusted ? "Untrust" : "Trust"
            onActivated: root.trustRequested(!root.device.trusted)
        }

        RailActionPill {
            objectName: "bluetooth-forget"
            visible: root.device.paired || root.device.trusted
            label: root.confirmForget ? "Confirm forget" : "Forget"
            destructive: root.confirmForget
            onActivated: root.forgetRequested()
        }
    }
}
