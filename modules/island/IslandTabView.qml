import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

Item {
    id: root

    property alias currentIndex: view.currentIndex
    property alias count: tabModel.count
    property alias moving: view.moving
    property var activePlayer: null

    PathView {
        id: view
        anchors.fill: parent
        anchors.topMargin: FrameConfig.pathViewTopMargin
        anchors.bottomMargin: FrameConfig.indicatorRowBottomMargin + 10 
        
        model: tabModel
        pathItemCount: 3
        snapMode: PathView.SnapOneItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        dragMargin: width / 2
        
        path: Path {
            startX: -view.width * 0.5; startY: view.height / 2
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathLine { x: 0; y: view.height / 2 }
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathLine { x: view.width * 0.5; y: view.height / 2 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathLine { x: view.width; y: view.height / 2 }
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathLine { x: view.width * 1.5; y: view.height / 2 }
            PathAttribute { name: "itemOpacity"; value: 0.0 }
        }

        delegate: Item {
            width: root.width - 40; height: view.height
            opacity: PathView.itemOpacity
            enabled: PathView.isCurrentItem

            Loader {
                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                sourceComponent: {
                    if (!model) return null;
                    if (model.type === "timeDate") return timeDateComp
                    if (model.type === "music") return musicComp
                    if (model.type === "weather") return weatherComp
                    if (model.type === "battery") return batteryComp
                    if (model.type === "notif") return notifComp
                    if (model.type === "cc") return ccComp
                    return null
                }
            }
        }
    }

    Component { id: timeDateComp; TimeDate { } }
    Component { id: musicComp; Music { player: root.activePlayer } }
    Component { id: weatherComp; Weather { } }
    Component { id: batteryComp; Battery {} }
    Component { id: notifComp; NotificationTab { } } 
    Component { id: ccComp; ControlCenter { } }

    ListModel {
        id: tabModel
        function updateModel() {
            clear();
            append({ "type": "timeDate" })
            append({ "type": "music" })
            append({ "type": "notif" })
            if (BatteryService.hasUPower && BatteryService.device && BatteryService.device.type !== 0) append({ "type": "battery" })
            if (FrameConfig.showWeather) append({ "type": "weather" })
            append({ "type": "cc" })
        }
        Component.onCompleted: updateModel()
    }
    
    Connections {
        target: FrameConfig
        function onShowWeatherChanged() { tabModel.updateModel() }
    }
    
    Connections {
        target: BatteryService
        function onHasUPowerChanged() { tabModel.updateModel() }
    }
}
