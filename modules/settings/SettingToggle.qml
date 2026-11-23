import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

Item {
    id: root

    required property string title
    required property string description
    required property bool checked
    property bool dangerous: false
    signal toggled(bool newValue)

    implicitHeight: 48

    RowLayout {
        anchors.fill: parent
        spacing: Design.space12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.title
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
                font.weight: Font.DemiBold
            }
            Text {
                text: root.description
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
                elide: Text.ElideRight
            }
        }

        ToggleSwitch {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            checked: root.checked
            activeColor: root.dangerous ? Theme.statusDanger : Theme.accent
            accessibleName: root.title
            onToggled: checked => root.toggled(checked)
        }
    }
}
