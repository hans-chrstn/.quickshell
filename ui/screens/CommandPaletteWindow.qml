import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import qs.ui.shared.effects
import qs.ui.features.island.app

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (visible && !closing) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property string screenName: (root.screen) ? root.screen.name : ""
    visible: !!ViewManager.activeWindows["commandPalette"] && (ViewManager.lastActiveScreenName === screenName)
    property bool closing: !!ViewManager.closingWindows["commandPalette"]
    property bool entryActive: false
    readonly property bool showContent: visible && !closing && entryActive

    onVisibleChanged: {
        if (visible) {
            entryTimer.restart()
        } else {
            entryActive = false
        }
    }

    Timer {
        id: entryTimer
        interval: 50
        onTriggered: {
            entryActive = true
            searchInput.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.showContent ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: ViewManager.closeWindow("commandPalette")
        }
    }

    Item {
        id: container
        width: 700
        height: resultsList.contentHeight + 120 > 600 ? 600 : resultsList.contentHeight + 120
        anchors.centerIn: parent
        
        opacity: root.showContent ? 1.0 : 0
        scale: root.showContent ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { 
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutExpo
            }
        }

        AdvancedGlass {
            anchors.fill: parent
            cornerRadius: 24
            blurRadius: 40
            overlayOpacity: 0.8
            overlayColor: "#0A0A0B"
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: "transparent"
            border.color: ThemeManager.outlineStrongColor
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    StyledLabel {
                        text: ThemeManager.iconSearch
                        type: "title"
                        font.pixelSize: 22
                        customColor: ThemeManager.accentColor
                        opacity: searchInput.activeFocus ? 1.0 : 0.4
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: ThemeManager.contentOnBackgroundColor
                        font.family: ThemeManager.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        selectionColor: ThemeManager.accentColor
                        text: CommandPaletteManager.searchText
                        
                        onTextChanged: CommandPaletteManager.searchText = text

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Up) {
                                CommandPaletteManager.selectedIndex = Math.max(0, CommandPaletteManager.selectedIndex - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                CommandPaletteManager.selectedIndex = Math.min(CommandPaletteManager.model.count - 1, CommandPaletteManager.selectedIndex + 1)
                                event.accepted = true
                            }
                        }

                        onAccepted: CommandPaletteManager.executeSelected()

                        StyledLabel {
                            text: "Search apps or system commands..."
                            type: "body"
                            font.pixelSize: 18
                            opacity: 0.15
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.05
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: CommandPaletteManager.model
                spacing: 2
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: CommandPaletteManager.selectedIndex
                
                header: Item { height: 8 }
                footer: Item { height: 8 }

                delegate: BaseButton {
                    id: delegateButton
                    width: resultsList.width
                    height: 54
                    cornerRadius: 12
                    hoverScale: 1.0
                    
                    onClicked: {
                        CommandPaletteManager.selectedIndex = index
                        CommandPaletteManager.executeSelected()
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: index === CommandPaletteManager.selectedIndex ? ThemeManager.accentColor : (parent.isHovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            Item {
                                width: 32
                                height: 32
                                Layout.alignment: Qt.AlignVCenter
                                
                                AppIslandIcon {
                                    anchors.fill: parent
                                    app: (model.type === "app" || model.type === "browser") ? DesktopEntries.applications.values.find(a => a.id === model.id) : null
                                    visible: model.type === "app" || model.type === "browser"
                                    iconSize: 32
                                    cornerRadius: 8
                                    isHovered: false 
                                }

                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: {
                                        if (model.type === "system") return model.icon
                                        if (model.type === "cmd") return "󰆍"
                                        if (model.type === "calc") return "󰪚"
                                        if (model.type === "window") return "󰖯"
                                        if (model.type === "clip") return "󰅍"
                                        return ""
                                    }
                                    type: "icon"
                                    font.pixelSize: 20
                                    visible: model.type !== "app" && model.type !== "browser"
                                    customColor: index === CommandPaletteManager.selectedIndex ? ThemeManager.contentPrimaryColor : ThemeManager.accentColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Layout.alignment: Qt.AlignVCenter

                                StyledLabel {
                                    text: model.name
                                    type: "label"
                                    font.weight: index === CommandPaletteManager.selectedIndex ? Font.Bold : Font.Normal
                                    font.pixelSize: 14
                                    customColor: index === CommandPaletteManager.selectedIndex ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                                    elideMode: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledLabel {
                                    text: {
                                        if (model.type === "cmd") return model.description
                                        if (model.type === "calc") return "Result (Enter to copy)"
                                        if (model.type === "window") return model.description
                                        if (model.type === "clip") return "Press Enter to copy snippet"
                                        if (model.type === "browser") return "Search web for \"" + model.description + "\""
                                        return model.type === "app" ? (model.description || "Application") : "System Action"
                                    }
                                    type: "caption"
                                    font.pixelSize: 11
                                    opacity: index === CommandPaletteManager.selectedIndex ? 0.7 : 0.4
                                    customColor: index === CommandPaletteManager.selectedIndex ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                                    elideMode: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            StyledLabel {
                                text: index === CommandPaletteManager.selectedIndex ? "󰁔" : ""
                                type: "icon"
                                font.pixelSize: 14
                                customColor: ThemeManager.contentPrimaryColor
                                visible: index === CommandPaletteManager.selectedIndex
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: ViewManager.closeWindow("commandPalette")
    }
}
