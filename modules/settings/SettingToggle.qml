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

    implicitHeight: 38

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.title
                color: root.dangerous ? Theme.danger : Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Text {
                text: root.description
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 9
            }
        }

        ToggleSwitch {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: 43
            Layout.preferredHeight: 25
            checked: root.checked
            activeColor: root.dangerous ? Theme.statusDanger : Theme.selection
            accessibleName: root.title
            onToggled: checked => root.toggled(checked)
        }
    }
}
