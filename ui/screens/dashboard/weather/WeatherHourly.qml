import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

StyledCard {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 120
    backgroundColor: Qt.rgba(1, 1, 1, 0.02)

    ListView {
        id: hourlyList
        anchors.fill: parent
        anchors.margins: 15
        orientation: ListView.Horizontal
        model: WeatherManager.hourlyStore
        spacing: 20
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: ColumnLayout {
            width: 45
            height: hourlyList.height
            spacing: 5

            StyledLabel {
                text: String(model.timeLabel || "")
                type: "caption"
                font.pixelSize: 12
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: String(model.icon || "")
                font.pixelSize: 24
                color: ThemeManager.accentColor
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
            }

            StyledLabel {
                text: Math.round(model.temp || 0) + "°"
                type: "body"
                font.weight: Font.Bold
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
