import QtQuick
import QtQuick.Layouts
import qs.core
import qs.controlcenter

Item {
    id: root

    GridLayout {
        anchors.fill: parent
        columns: root.width >= 520 ? 2 : 1
        rowSpacing: Design.space12
        columnSpacing: Design.space12

        AudioLevelCard {
            role: "output"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
        }

        AudioLevelCard {
            role: "input"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
        }
    }
}
