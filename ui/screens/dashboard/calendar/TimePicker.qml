import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root

    property string time: "12:00"
    
    readonly property int initialHour: parseInt(time.split(":")[0])
    readonly property int initialMinute: parseInt(time.split(":")[1])

    width: 110
    height: 110
    color: Qt.rgba(0, 0, 0, 0.4)
    radius: 12
    border.color: Qt.rgba(1, 1, 1, 0.1)
    clip: true

    function syncTime() {
        let h = hourList.currentIndex.toString().padStart(2, '0')
        let m = minuteList.model[minuteList.currentIndex].toString().padStart(2, '0')
        let newTime = h + ":" + m
        if (root.time !== newTime) {
            root.time = newTime
        }
    }

    component ScrollColumn : ListView {
        id: lv
        Layout.fillHeight: true
        Layout.preferredWidth: 45
        
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: height / 2 - 15
        preferredHighlightEnd: height / 2 + 15
        
        currentIndex: 0
        clip: true
        interactive: true
        
        onCurrentIndexChanged: root.syncTime()

        delegate: Item {
            width: lv.width
            height: 30
            
            readonly property bool isSelected: lv.currentIndex === index

            StyledLabel {
                anchors.centerIn: parent
                text: modelData.toString().padStart(2, '0')
                type: "body"
                font.pixelSize: isSelected ? 18 : 12
                font.weight: isSelected ? Font.Bold : Font.Normal
                opacity: isSelected ? 1.0 : 0.2
                color: isSelected ? ThemeManager.accentColor : "#FFFFFF"
                
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
            }

            TapHandler {
                onTapped: lv.currentIndex = index
            }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: (event) => {
                if (event.angleDelta.y > 0) lv.decrementCurrentIndex()
                else lv.incrementCurrentIndex()
            }
            propagateComposedEvents: true
            onPressed: (mouse) => { mouse.accepted = false }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 0

        ScrollColumn {
            id: hourList
            model: 24
            
            Component.onCompleted: {
                currentIndex = root.initialHour
            }
        }

        StyledLabel {
            text: ":"
            type: "title"
            font.pixelSize: 20
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        ScrollColumn {
            id: minuteList
            model: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
            
            Component.onCompleted: {
                let m = root.initialMinute
                let steps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
                let closest = 0
                let minDiff = 60
                for (let i = 0; i < steps.length; i++) {
                    let diff = Math.abs(m - steps[i])
                    if (diff < minDiff) {
                        minDiff = diff
                        closest = i
                    }
                }
                currentIndex = closest
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 10
        height: 30
        color: Qt.rgba(1, 1, 1, 0.05)
        radius: 6
        z: -1
        border.color: Qt.rgba(1, 1, 1, 0.1)
    }
}
