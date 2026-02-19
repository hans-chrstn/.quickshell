import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root
    height: 50
    color: "transparent"

    property string highlightedLetter: ""
    property var alphabetModel: "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".split('')

    signal letterClicked(string letter)

    Row {
        id: letterRow
        anchors.centerIn: parent
        spacing: FrameConfig.appIslandScrubberSpacing

        Repeater {
            model: root.alphabetModel
            
            delegate: Text {
                text: modelData
                font.pixelSize: FrameConfig.appIslandScrubberFontSize
                font.weight: root.highlightedLetter === modelData ? Font.Bold : Font.Normal
                color: "white"
                horizontalAlignment: Text.AlignHCenter

                opacity: root.highlightedLetter === modelData ? 1.0 : 0.3
                scale: root.highlightedLetter === modelData ? 1.2 : 1.0

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                MouseArea {
                    anchors.fill: parent
                    width: 14; height: 30
                    anchors.centerIn: parent
                    onClicked: root.letterClicked(modelData)
                }
            }
        }
    }
}