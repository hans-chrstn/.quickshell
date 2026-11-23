import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root

    required property string label
    required property string value

    implicitHeight: 48
    spacing: Design.space2

    Text {
        Layout.fillWidth: true
        text: root.value
        color: Theme.textPrimary
        font.family: Design.fontMono
        font.pixelSize: Design.typeTitle
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.textSecondary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
        elide: Text.ElideRight
    }
}
