import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard.clipboard

ColumnLayout {
    id: root

    property bool active: false

    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

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
            visible: {
                if (!ClipboardManager) {
                    return false
                }
                return ClipboardManager.history.length > 0
            }

            onClicked: {
                if (ClipboardManager) {
                    ClipboardManager.clear()
                    SoundManager.playCollapse()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: {
                    if (parent.isHovered) {
                        return ThemeManager.surfaceStrongColor
                    }
                    return "transparent"
                }
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: "󰃢"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 20
                opacity: {
                    if (parent.isHovered) {
                        return 1.0
                    }
                    return 0.6
                }
            }
        }
    }

    ListView {
        id: clipList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: {
            if (!ClipboardManager) {
                return null
            }
            return ClipboardManager.history
        }
        spacing: 8
        clip: true

        delegate: ClipboardItemDelegate {
            content: String(modelData || "")
        }
    }

    StyledLabel {
        text: "History is empty"
        type: "caption"
        opacity: 0.3
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        visible: {
            if (!ClipboardManager) {
                return true
            }
            return ClipboardManager.history.length === 0
        }
    }
}
