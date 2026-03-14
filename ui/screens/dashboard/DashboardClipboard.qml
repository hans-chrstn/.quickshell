import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    property bool active: false

    RowLayout {
        Layout.fillWidth: true

        StyledLabel {
            text: "Clipboard"
            type: "heading"
            font.pixelSize: 28
            Layout.fillWidth: true
        }

        BaseButton {
            width: 44
            height: 44
            cornerRadius: 12
            tooltip: "Clear History"
            visible: ClipboardManager.history.length > 0

            onClicked: {
                ClipboardManager.clear()
                SoundManager.playCollapse()
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: parent.isHovered 
                    ? ThemeManager.surfaceStrongColor 
                    : "transparent"
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: "󰃢"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 20
                opacity: parent.isHovered ? 1.0 : 0.6
            }
        }
    }

    ListView {
        id: clipList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: ClipboardManager.history
        spacing: 8
        clip: true

        delegate: BaseButton {
            width: clipList.width
            height: 60
            cornerRadius: 12
            hoverScale: 1.0

            readonly property string clipContent: modelData || ""

            onClicked: {
                if (clipContent) {
                    ClipboardManager.copyToClipboard(clipContent)
                    SoundManager.playSuccess()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: parent.isHovered 
                    ? ThemeManager.surfaceStrongColor 
                    : ThemeManager.surfacePrimaryColor
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }

            StyledLabel {
                anchors.fill: parent
                anchors.margins: 15
                text: clipContent.replace(/\n/g, " ")
                type: "body"
                elideMode: Text.ElideRight
                font.pixelSize: 13
            }
        }
    }

    StyledLabel {
        text: "History is empty"
        type: "caption"
        opacity: 0.3
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        visible: ClipboardManager.history.length === 0
    }
}
