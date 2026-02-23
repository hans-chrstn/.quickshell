import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import qs.services
import qs.components

Row {
    id: root
    spacing: 8
    height: ThemeService.thickness
    
    // Repeater {
    //     model: SystemTrayService.values
    //     
    //     delegate: Item {
    //         id: delegateRoot
    //         width: 12
    //         height: ThemeService.thickness
    //         anchors.verticalCenter: parent.verticalCenter
    //
    //         Rectangle {
    //             id: dot
    //             anchors.centerIn: parent
    //             width: 6; height: 6; radius: 3
    //             
    //             color: (SystemTrayService.hoveredIndex === index) 
    //                 ? Qt.rgba(ThemeService.backgroundContent.r, ThemeService.backgroundContent.g, ThemeService.backgroundContent.b, 1.0)
    //                 : Qt.rgba(ThemeService.backgroundContent.r, ThemeService.backgroundContent.g, ThemeService.backgroundContent.b, 0.5)
    //
    //             Behavior on color { ColorAnimation { duration: 200 } }
    //         }
    //
    //         HoverHandler { 
    //             id: hh
    //             onHoveredChanged: {
    //                 if (hovered) SystemTrayService.hoveredIndex = index
    //                 else if (SystemTrayService.hoveredIndex === index) SystemTrayService.hoveredIndex = -1
    //             }
    //         }
    //         
    //         TapHandler {
    //             onTapped: modelData.activate()
    //         }
    //     }
    // }
}
