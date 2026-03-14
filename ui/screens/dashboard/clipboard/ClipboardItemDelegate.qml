import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root

    property string content: ""
    
    width: parent ? parent.width : 0
    height: 60
    cornerRadius: 12
    hoverScale: 1.0

    onClicked: {
        if (root.content !== "") {
            ClipboardManager.copyToClipboard(root.content)
            SoundManager.playSuccess()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: {
            if (root.isHovered) {
                return ThemeManager.surfaceStrongColor
            }
            return ThemeManager.surfacePrimaryColor
        }
        border.color: ThemeManager.outlineVariantColor
        border.width: 1
    }

    StyledLabel {
        anchors.fill: parent
        anchors.margins: 15
        text: {
            return root.content.replace(/\n/g, " ")
        }
        type: "body"
        elideMode: Text.ElideRight
        font.pixelSize: 13
    }
}
