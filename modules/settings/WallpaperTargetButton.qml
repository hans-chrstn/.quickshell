import QtQuick
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property string label
    signal activated

    implicitWidth: Math.max(Design.minimumTouchTarget, labelText.implicitWidth + Design.space24)
    implicitHeight: Design.minimumTouchTarget
    accentColor: Theme.accent
    baseColor: Theme.fillSubtle
    cornerRadius: Design.radiusControl
    onSurfaceActivated: root.activated()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? Theme.textPrimary : Theme.textSecondary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
        font.weight: Font.Medium
    }
}
