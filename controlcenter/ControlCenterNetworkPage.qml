import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.controlcenter
import qs.services.network

FocusScope {
    id: root

    readonly property var links: NetworkService.wiredLinks
    readonly property var primaryLink: links.find(link => link.connected) || links[0] || null

    focus: true

    Component.onCompleted: NetworkService.setConsumer("control-center.network", true)
    Component.onDestruction: NetworkService.setConsumer("control-center.network", false)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            ControlCenterService.close();
            event.accepted = true;
        }
    }

    IslandGlyph {
        id: titleGlyph
        x: Design.space20
        y: Design.space20
        width: 25
        height: 25
        name: "ethernet"
        glyphColor: Theme.accent
    }

    Text {
        x: titleGlyph.x + titleGlyph.width + Design.space12
        anchors.verticalCenter: titleGlyph.verticalCenter
        text: "Ethernet"
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
        accessibleName: "Close network information"
        onActivated: ControlCenterService.close()
    }

    Rectangle {
        id: mainCard
        x: Design.space20
        y: 70
        width: parent.width - Design.space20 * 2
        height: 122
        radius: Design.radiusGrouped
        color: Theme.fillSubtle
        border.color: Theme.separator

        IconMark {
            x: Design.space20
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 48
            glyph: "ethernet"
            glyphSize: 25
            glyphColor: root.primaryLink?.connected ? Theme.statusSuccess : Theme.textSecondary
        }

        Column {
            x: 84
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - Design.space20
            spacing: Design.space4

            Text {
                width: parent.width
                text: root.primaryLink?.connected ? "Connected" : root.links.length > 0 ? "Disconnected" : NetworkService.backend === "none" ? "Unavailable" : "No Ethernet device"
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: Design.typeTitle
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.primaryLink?.model || root.primaryLink?.name || "Network information is unavailable"
                elide: Text.ElideRight
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
            }

            Text {
                width: parent.width
                visible: !!root.primaryLink?.address
                text: root.primaryLink?.address || ""
                color: Theme.textTertiary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
            }
        }
    }

    Text {
        x: Design.space24
        y: mainCard.y + mainCard.height + Design.space20
        text: "DETAILS"
        color: Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: Design.typeCaption
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
    }

    Rectangle {
        id: detailCard
        x: Design.space20
        y: mainCard.y + mainCard.height + 42
        width: parent.width - Design.space20 * 2
        height: 196
        radius: Design.radiusGrouped
        color: Theme.fillSubtle
        border.color: Theme.separator

        Column {
            anchors.fill: parent
            anchors.margins: Design.space16
            spacing: 0

            Repeater {
                model: [
                    {
                        label: "Interface",
                        value: root.primaryLink?.name || "—"
                    },
                    {
                        label: "IPv4 address",
                        value: root.primaryLink?.address || "—"
                    },
                    {
                        label: "Gateway",
                        value: root.primaryLink?.gateway || "—"
                    },
                    {
                        label: "DNS",
                        value: root.primaryLink?.dns || "—"
                    },
                    {
                        label: "Hardware address",
                        value: root.primaryLink?.hardwareAddress || "—"
                    }
                ]

                Item {
                    required property var modelData
                    width: parent.width
                    height: 33

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value
                        color: Theme.textPrimary
                        font.family: Design.fontMono
                        font.pixelSize: Design.typeBody
                    }
                }
            }
        }
    }

    Text {
        x: Design.space24
        y: detailCard.y + detailCard.height + Design.space16
        text: NetworkService.backend === "networkd" ? "systemd-networkd" : NetworkService.backend === "networkmanager" ? "NetworkManager" : "Network service unavailable"
        color: Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: Design.typeCaption
    }
}
