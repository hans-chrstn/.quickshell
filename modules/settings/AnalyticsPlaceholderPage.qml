import QtQuick
import QtQuick.Layouts
import qs.core

SettingPage {
    id: root

    required property string title
    required property string description

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader { title: root.title }

        Text {
            Layout.fillWidth: true
            text: root.description
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        Item { Layout.fillHeight: true }
    }
}
