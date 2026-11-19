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
    Layout.bottomMargin: Design.space8

    HighlightableSurface {
        id: backButton
        width: 30
        height: 30
        visible: SettingsService.currentPage !== ""
        interactive: visible
        focused: hovered
        baseColor: "transparent"
        cornerRadius: Design.radiusControl
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
        font.pixelSize: Design.typeDisplay
        font.weight: Font.DemiBold
    }
}
