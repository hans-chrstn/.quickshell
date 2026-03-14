import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Rectangle {
    id: root

    property int hours: 0
    property int minutes: 0
    property string time: "12:00"

    signal timePicked(int h, int m)

    implicitWidth: layout.implicitWidth + 30
    implicitHeight: 110
    radius: 12
    color: Qt.rgba(1, 1, 1, 0.03)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    onTimeChanged: {
        let parts = time.split(":")
        if (parts.length === 2) {
            let h = parseInt(parts[0])
            let m = parseInt(parts[1])
            if (!isNaN(h) && h !== hours) hours = h
            if (!isNaN(m) && m !== minutes) minutes = m
        }
    }

    function _updateTime() {
        let newTime = hours.toString().padStart(2, '0') + ":" + minutes.toString().padStart(2, '0')
        if (time !== newTime) time = newTime
    }

    onHoursChanged: _updateTime()
    onMinutesChanged: _updateTime()

    SystemClock {
        id: globalSystemClock
        precision: SystemClock.Minutes
    }

    Component.onCompleted: {
        if (root.time === "12:00" && root.hours === 0 && root.minutes === 0) {
            root.hours = globalSystemClock.date.getHours()
            root.minutes = globalSystemClock.date.getMinutes()
            root._updateTime()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 16
        height: 36
        radius: 6
        color: Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(1, 1, 1, 0.04)
        z: 1
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12
        z: 2

        RollingColumn {
            value: root.hours
            maxValue: 24
            onChanged: (val) => root.hours = val
        }

        StyledLabel {
            text: ":"
            type: "clock"
            font.pixelSize: 22
            opacity: 0.3
            Layout.alignment: Qt.AlignVCenter
        }

        RollingColumn {
            value: root.minutes
            maxValue: 60
            onChanged: (val) => root.minutes = val
        }
    }

    component RollingColumn : Item {
        id: column
        property int value: 0
        property int maxValue: 24
        property int itemHeight: 36
        
        signal changed(int newValue)

        implicitWidth: 44
        implicitHeight: itemHeight * 3
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            y: offset
            
            property real offset: 0

            Repeater {
                model: 3
                delegate: Item {
                    width: column.width
                    height: column.itemHeight
                    
                    readonly property int displayValue: {
                        let val = column.value + (index - 1)
                        if (val < 0) return column.maxValue + val
                        return val % column.maxValue
                    }
                    
                    readonly property bool isCenter: index === 1
                    readonly property real dist: Math.abs(contentColumn.offset) / column.itemHeight

                    StyledLabel {
                        anchors.centerIn: parent
                        text: displayValue.toString().padStart(2, '0')
                        type: "clock"
                        font.pixelSize: isCenter ? (22 - (dist * 8)) : (14 + (dist * 6))
                        opacity: isCenter ? (1.0 - dist) : (0.2 + (dist * 0.4))
                        color: isCenter ? ThemeManager.accentColor : "#FFFFFF"
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            property int lastY: 0
            enabled: root.enabled
            
            onPressed: (mouse) => {
                lastY = mouse.y
                snapAnim.stop()
            }

            onPositionChanged: (mouse) => {
                let diff = mouse.y - lastY
                contentColumn.offset += diff
                
                if (contentColumn.offset > column.itemHeight / 2) {
                    column.changed((column.value + column.maxValue - 1) % column.maxValue)
                    contentColumn.offset -= column.itemHeight
                    SoundManager.playClick()
                } else if (contentColumn.offset < -column.itemHeight / 2) {
                    column.changed((column.value + 1) % column.maxValue)
                    contentColumn.offset += column.itemHeight
                    SoundManager.playClick()
                }
                lastY = mouse.y
            }

            onReleased: snapAnim.start()
            
            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    column.changed((column.value + column.maxValue - 1) % column.maxValue)
                } else {
                    column.changed((column.value + 1) % column.maxValue)
                }
                SoundManager.playClick()
                snapAnim.restart()
            }
        }

        NumberAnimation {
            id: snapAnim
            target: contentColumn
            property: "offset"
            to: 0
            duration: 250
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }
}
