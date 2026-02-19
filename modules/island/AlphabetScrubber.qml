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
        spacing: 5

        Repeater {
            model: root.alphabetModel
            
            delegate: Text {
                text: modelData
                font.pixelSize: FrameConfig.appIslandScrubberFontSize
                color: "white"
                horizontalAlignment: Text.AlignHCenter

                opacity: root.highlightedLetter === modelData ? FrameConfig.appIslandScrubberActiveOpacity : FrameConfig.appIslandScrubberInactiveOpacity
                scale: root.highlightedLetter === modelData ? FrameConfig.appIslandScrubberActiveScale : FrameConfig.appIslandScrubberInactiveScale

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.letterClicked(modelData)
                }
            }
        }
    }
}