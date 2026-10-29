import QtQuick
import qs.components

ValueSlider {
    id: root

    signal levelEdited(real value)
    signal stepRequested(int steps)

    from: 0
    to: 1
    stepSize: 0.01
    wheelStepEnabled: true
    Accessible.name: "Sound level"
    onEditRequested: value => root.levelEdited(value)
    onWheelStepRequested: steps => root.stepRequested(steps)
}
