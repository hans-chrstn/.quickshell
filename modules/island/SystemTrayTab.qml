import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.components

Item {
    id: root
    anchors.fill: parent

    RowLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, layoutContent.implicitWidth)
        height: 70
        spacing: 20

        RowLayout {
            id: layoutContent
            spacing: 20
            Layout.alignment: Qt.AlignVCenter

            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "SYSTEM"
                    color: ThemeService.backgroundContent
                    font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 2
                    opacity: 0.4
                }
                Text {
                    text: "SERVICES"
                    color: ThemeService.backgroundContent
                    font.pixelSize: 12; font.weight: Font.Bold
                }
            }

            Rectangle {
                width: 1; height: 24
                color: ThemeService.backgroundContent; opacity: 0.1
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: SystemTrayService.values
                    delegate: Rectangle {
                        id: trayIconBox
                        width: 36; height: 36; radius: 10
                        color: hh.hovered ? ThemeService.surfaceVariantStrong : ThemeService.surfaceVariant
                        
                        readonly property bool needsAttention: modelData.status === SystemTrayItem.NeedsAttention
                        border.color: needsAttention ? ThemeService.dangerMain : ThemeService.backgroundContent
                        border.width: needsAttention || hh.hovered ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                        scale: hh.hovered ? 1.1 : 1.0

                        IconImage {
                            anchors.fill: parent; anchors.margins: 8
                            source: modelData.icon
                        }

                        HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
                        
                        TapHandler {
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onTapped: {
                                if (tap.button === Qt.RightButton) {
                                    modelData.secondaryActivate()
                                } else {
                                    modelData.activate()
                                }
                                SfxService.playButton2()
                            }
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.top; anchors.bottomMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(lbl.implicitWidth, desc.implicitWidth) + 20
                            height: desc.text !== "" ? 32 : 22; radius: 8
                            color: ThemeService.backgroundMain
                            border.color: ThemeService.outlineMain; border.width: 1
                            opacity: hh.hovered ? 1.0 : 0.0
                            visible: opacity > 0.01
                            
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    id: lbl
                                    text: (modelData.title || "APP").toUpperCase()
                                    color: ThemeService.backgroundContent
                                    font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 1
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    id: desc
                                    text: modelData.tooltipDescription || ""
                                    color: ThemeService.backgroundContent
                                    font.pixelSize: 7; font.weight: Font.Medium; opacity: 0.5
                                    visible: text !== ""
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
