import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.settings

RowLayout {
    id: root

    property string title: ""

    Layout.fillWidth: true
    spacing: 10
    Layout.bottomMargin: 4

    Rectangle {
        id: backButton
        width: 24
        height: 24
        radius: 12
        color: backHover.hovered ? Design.surfaceRaised : "transparent"
        scale: backTap.pressed ? 0.94 : 1
        visible: SettingsService.currentPage !== ""

        IslandGlyph {
            anchors.centerIn: parent
            name: "chevronLeft"
            glyphColor: backHover.hovered ? Design.text : Design.textMuted
            scale: backTap.pressed ? 0.9 : 1
        }

        HoverHandler { id: backHover }
        TapHandler {
            id: backTap
            onTapped: SettingsService.back()
        }
    }

    Text {
        text: root.title
        color: Design.text
        font.family: Design.fontDisplay
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }
}
