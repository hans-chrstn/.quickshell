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

    HighlightableSurface {
        id: backButton
        width: 24
        height: 24
        visible: SettingsService.currentPage !== ""
        interactive: visible
        focused: hovered
        baseColor: "transparent"
        cornerRadius: 12
        onSurfaceActivated: SettingsService.back()

        IslandGlyph {
            anchors.centerIn: parent
            name: "chevronLeft"
            glyphColor: backButton.hovered ? Theme.textPrimary : Theme.textSecondary
        }
    }

    Text {
        text: root.title
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }
}
