import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.settings

RowLayout {
    id: root

    property string title: ""

    Layout.fillWidth: true
    spacing: Design.space12
    Layout.bottomMargin: Design.space8

    HighlightableSurface {
        id: backButton
        width: Design.minimumTouchTarget
        height: Design.minimumTouchTarget
        visible: SettingsService.currentPage !== ""
        interactive: visible
        accessibleName: "Back to previous settings page"
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
