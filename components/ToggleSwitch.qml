import QtQuick
import qs.core

InteractionFrame {
    id: root

    required property bool checked
    property color activeColor: Theme.selection
    property string accessibleName: "Toggle"
    signal toggled(bool checked)

    implicitWidth: 43
    implicitHeight: 25
    selected: checked
    selectionFillEnabled: false
    baseColor: "transparent"
    cornerRadius: height / 2 + 3
    controlInset: -3
    onTriggered: root.toggled(!root.checked)

    Accessible.role: Accessible.CheckBox
    Accessible.name: accessibleName
    Accessible.checked: checked
    Accessible.onPressAction: if (root.enabled)
        root.toggled(!root.checked)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? root.activeColor : Theme.fillStrong
        border.width: root.checked ? 0 : 1
        border.color: Theme.fillStrong

        Behavior on color {
            ColorAnimation {
                duration: Design.motionControlDuration
                easing.type: Design.motionStandardEasing
            }
        }

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 19
            height: 19
            radius: width / 2
            color: Theme.valueThumb

            Behavior on x {
                NumberAnimation {
                    duration: Design.motionTravelDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Design.motionControlCurve
                }
            }
        }
    }
}
