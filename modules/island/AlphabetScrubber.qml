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
                id: letterText
                text: modelData
                font.pixelSize: FrameConfig.appIslandScrubberFontSize
                font.weight: root.highlightedLetter === modelData ? Font.Black : Font.Medium
                color: "white"
                horizontalAlignment: Text.AlignHCenter

                readonly property real distance: {
                    if (!scrubberMouseArea.containsMouse) return 1000;
                    var localMouse = letterText.mapFromItem(scrubberMouseArea, scrubberMouseArea.mouseX, 0);
                    return Math.abs(localMouse.x - letterText.width / 2);
                }
                
                readonly property real magneticScale: {
                    if (distance < 20) return 1.5;
                    if (distance < 40) return 1.3;
                    if (distance < 80) return 1.1;
                    return 1.0;
                }

                opacity: root.highlightedLetter === modelData ? 1.0 : (scrubberMouseArea.containsMouse ? (1.0 - (Math.min(distance, 150) / 150) * 0.7) : 0.3)
                scale: root.highlightedLetter === modelData ? 1.3 : magneticScale

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                TapHandler {
                    onTapped: root.letterClicked(modelData)
                }
            }
        }
    }

    MouseArea {
        id: scrubberMouseArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
