import QtQuick
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property string label
    property bool dangerous: false
    signal clicked

    implicitWidth: labelText.implicitWidth + Design.space24
    implicitHeight: Design.minimumTouchTarget
    baseColor: "transparent"
    cornerRadius: Design.radiusControl
    outlineColor: dangerous ? Theme.tintBorder(Theme.danger) : Theme.separator
    externalFocus: dangerous && hovered
    accessibleName: label
    onSurfaceActivated: root.clicked()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.hovered || root.activeFocus ? Theme.textPrimary : Theme.textSecondary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
        font.weight: Font.DemiBold

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
            }
        }
    }
}
