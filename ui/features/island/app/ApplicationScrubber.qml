import QtQuick
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    height: 50
    color: "transparent"

    property string activeLetter: ""
    property var alphabetItems: "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".split('')

    signal letterSelected(string letter)

    Row {
        id: scrubberRow
        anchors.centerIn: parent
        spacing: ThemeManager.appIslandScrubberSpacing

        Repeater {
            model: root.alphabetItems
            
            delegate: StyledLabel {
                id: letterVisual
                text: modelData
                type: "caption"
                font.weight: root.activeLetter === modelData ? Font.Black : Font.Medium
                horizontalAlignment: Text.AlignHCenter

                readonly property real mouseDistance: {
                    if (!interactionMouseArea.containsMouse) return 1000;
                    let localPoint = letterVisual.mapFromItem(interactionMouseArea, interactionMouseArea.mouseX, 0);
                    return Math.abs(localPoint.x - letterVisual.width / 2);
                }
                
                readonly property real magnificationFactor: {
                    if (mouseDistance < 20) return 1.5;
                    if (mouseDistance < 40) return 1.3;
                    if (mouseDistance < 80) return 1.1;
                    return 1.0;
                }

                opacity: root.activeLetter === modelData ? 1.0 : (interactionMouseArea.containsMouse ? (1.0 - (Math.min(mouseDistance, 150) / 150) * 0.7) : 0.3)
                scale: root.activeLetter === modelData ? 1.3 : magnificationFactor

                Behavior on opacity { NumberAnimation { duration: ThemeManager.durationInstant } }
                Behavior on scale { 
                    NumberAnimation { 
                        duration: ThemeManager.durationMedium
                        easing.type: Easing.OutBack 
                    } 
                }

                TapHandler {
                    onTapped: root.letterSelected(modelData)
                }
            }
        }
    }

    MouseArea {
        id: interactionMouseArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
