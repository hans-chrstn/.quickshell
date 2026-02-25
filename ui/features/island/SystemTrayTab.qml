import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.core
import qs.ui.shared

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
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 2
                    opacity: 0.4
                }
                Text {
                    text: "SERVICES"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 12; font.weight: Font.Bold
                }
            }

            Rectangle {
                width: 1; height: 24
                color: ThemeManager.contentOnBackgroundColor; opacity: 0.1
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: SystemTrayManager.items
                    delegate: Rectangle {
                        id: trayIconBox
                        width: 36; height: 36; radius: 10
                        color: hh.hovered ? ThemeManager.surfaceVariantStrongColor : ThemeManager.surfaceVariantColor
                        
                        readonly property bool needsAttention: modelData.status === SystemTrayItem.NeedsAttention
                        border.color: needsAttention ? ThemeManager.dangerPrimaryColor : ThemeManager.contentOnBackgroundColor
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
                            onTapped: (point) => {
                                if (point.pressedButtons & Qt.RightButton) {
                                    modelData.secondaryActivate()
                                } else {
                                    modelData.activate()
                                }
                                SoundManager.playToggle()
                            }
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.top; anchors.bottomMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(lbl.implicitWidth, desc.implicitWidth) + 20
                            height: desc.text !== "" ? 32 : 22; radius: 8
                            color: ThemeManager.backgroundPrimaryColor
                            border.color: ThemeManager.outlinePrimaryColor; border.width: 1
                            opacity: hh.hovered ? 1.0 : 0.0
                            visible: opacity > 0.01
                            
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    id: lbl
                                    text: (modelData.title || "APP").toUpperCase()
                                    color: ThemeManager.contentOnBackgroundColor
                                    font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 1
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    id: desc
                                    text: modelData.tooltipDescription || ""
                                    color: ThemeManager.contentOnBackgroundColor
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
