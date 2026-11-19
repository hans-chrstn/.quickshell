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

    implicitHeight: 44

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
                font.pixelSize: Design.typeBody
                font.weight: Font.DemiBold
            }
            Text {
                text: root.description
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeCaption
                elide: Text.ElideRight
            }
        }

        ToggleSwitch {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: 43
            Layout.preferredHeight: 25
            checked: root.checked
            activeColor: root.dangerous ? Theme.statusDanger : Theme.accent
            accessibleName: root.title
            onToggled: checked => root.toggled(checked)
        }
    }
}
