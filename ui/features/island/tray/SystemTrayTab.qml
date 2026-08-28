import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.core
import qs.ui.shared

Item {
    id: root
    anchors.fill: parent

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, layoutContent.implicitWidth)
        height: 70

        RowLayout {
            id: layoutContent
            anchors.centerIn: parent
            spacing: 20
            Layout.alignment: Qt.AlignVCenter

            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                StyledLabel {
                    text: "SYSTEM"
                    type: "caption"
                    font.weight: Font.Black; font.letterSpacing: 2; font.pixelSize: 8
                    opacity: 0.4
                }
                StyledLabel {
                    text: "SERVICES"
                    type: "body"
                    font.weight: Font.Bold; font.pixelSize: 12
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
                            onTapped: (tapPoint, button) => {
                                if (button === Qt.RightButton) {
                                    if (modelData.hasMenu) {
                                        trayMenuLoader.trayMenu = modelData.menu
                                        trayMenuLoader.active = true
                                    } else {
                                        modelData.secondaryActivate()
                                    }
                                } else {
                                    modelData.activate()
                                }
                                SoundManager.playToggle()
                            }
                        }

                        Loader {
                            id: trayMenuLoader
                            active: false
                            property var trayMenu: null

                            onLoaded: {
                                item.popup()
                                if (typeof dynamicIslandRoot !== "undefined") {
                                    dynamicIslandRoot.activeMenus++
                                }
                            }

                            onActiveChanged: {
                                if (!active) {
                                    trayMenu = null
                                    if (typeof dynamicIslandRoot !== "undefined") {
                                        dynamicIslandRoot.activeMenus--
                                    }
                                }
                            }

                            sourceComponent: Component {
                                BaseContextMenu {
                                    id: trayCtxMenu
                                    width: 220

                                    onClosed: {
                                        trayMenuLoader.active = false
                                    }

                                    QsMenuOpener {
                                        id: menuOpener
                                        menu: trayMenuLoader.trayMenu
                                    }

                                    Repeater {
                                        model: menuOpener.children
                                        delegate: MenuItem {
                                            id: menuItem
                                            visible: !modelData.isSeparator
                                            enabled: modelData.enabled !== false
                                            height: visible ? 32 : 0

                                            background: Rectangle {
                                                implicitWidth: 200
                                                implicitHeight: 32
                                                color: menuItem.hovered ? ThemeManager.surfaceVariantColor : "transparent"
                                                radius: 4
                                            }

                                            contentItem: StyledLabel {
                                                text: modelData.text || ""
                                                type: "caption"
                                                font.pixelSize: 11
                                                opacity: menuItem.enabled ? 1.0 : 0.4
                                                leftPadding: 8
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            HoverHandler {
                                                cursorShape: Qt.PointingHandCursor
                                            }

                                            onTriggered: {
                                                modelData.triggered()
                                                trayCtxMenu.close()
                                            }
                                        }
                                    }
                                }
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
                                StyledLabel {
                                    id: lbl
                                    text: (modelData.title || "APP").toUpperCase()
                                    type: "trayTooltip"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                StyledLabel {
                                    id: desc
                                    text: modelData.tooltipDescription || ""
                                    type: "caption"
                                    font.weight: Font.Medium; font.pixelSize: 7; opacity: 0.5
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
