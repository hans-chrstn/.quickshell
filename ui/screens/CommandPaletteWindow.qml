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
            LauncherManager.open()
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

    Item {
        id: contentArea
        anchors.fill: parent
        opacity: root.showContent ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        OrganicBlobs {
            anchors.fill: parent
            color1: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.15)
            color2: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.2)
            color3: ThemeManager.backgroundColor
            opacity: 0.4
        }

        AdvancedGlass {
            id: glassBackground
            anchors.fill: parent
            blurRadius: 64
            cornerRadius: 0
            overlayOpacity: 0.75
            overlayColor: "#050505"
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: ViewManager.closeWindow("commandPalette")
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            width: Math.min(parent.width - 120, 580)

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                Layout.bottomMargin: 30

                Rectangle {
                    anchors.fill: parent
                    radius: 32
                    color: "#1c1c1e"
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 31
                    color: "#101012"
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 31
                    color: "transparent"
                    border.color: ThemeManager.outlineStrongColor
                    border.width: 1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 16

                    StyledLabel {
                        text: ThemeManager.iconSearch
                        type: "heading"
                        font.pixelSize: 22
                        opacity: searchInput.activeFocus ? 1.0 : 0.3
                        customColor: ThemeManager.accentColor
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "#f5f5f7"
                        font.family: ThemeManager.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        selectionColor: ThemeManager.accentColor
                        text: LauncherManager.searchText

                        onTextChanged: LauncherManager.searchText = text

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Up) {
                                LauncherManager.selectedIndex = Math.max(0, LauncherManager.selectedIndex - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                LauncherManager.selectedIndex = Math.min(LauncherManager.model.count - 1, LauncherManager.selectedIndex + 1)
                                event.accepted = true
                            }
                        }

                        onAccepted: LauncherManager.executeSelected()

                        StyledLabel {
                            text: "Search anything..."
                            type: "title"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            letterSpacing: -0.35
                            opacity: 0.12
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 400
                Layout.fillHeight: true
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: "#1c1c1e"
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 19
                    color: "#101012"
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 19
                    color: "transparent"
                    border.color: ThemeManager.outlineStrongColor
                    border.width: 1
                }

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2
                    clip: true
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: LauncherManager.selectedIndex

                    model: LauncherManager.model

                    header: Item { height: 4 }
                    footer: Item { height: 4 }

                    delegate: Item {
                        id: itemRoot
                        width: resultsList.width
                        height: 52

                        property bool isSelected: index === LauncherManager.selectedIndex
                        property bool isHovered: itemMouse.containsMouse
                        readonly property bool highlight: isSelected || isHovered

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: itemRoot.isSelected ? Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.25) : (itemRoot.isHovered ? "#25282e" : "transparent")
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            color: itemRoot.highlight ? "#17191e" : "transparent"
                            opacity: itemRoot.highlight ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            color: "transparent"
                            border.color: itemRoot.isSelected ? ThemeManager.outlineStrongColor : "transparent"
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                LauncherManager.selectedIndex = index
                                LauncherManager.executeSelected()
                            }
                            onEntered: LauncherManager.selectedIndex = index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 14

                            Item {
                                width: 28
                                height: 28
                                Layout.alignment: Qt.AlignVCenter

                                AppIslandIcon {
                                    anchors.fill: parent
                                    app: (model.type === "app" || model.type === "browser") ? DesktopEntries.applications.values.find(a => a.id === model.id) : null
                                    visible: model.type === "app" || model.type === "browser"
                                    iconSize: 28
                                    cornerRadius: 6
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
                                    font.pixelSize: 18
                                    visible: model.type !== "app" && model.type !== "browser"
                                    customColor: ThemeManager.accentColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                StyledLabel {
                                    text: model.name
                                    type: "body"
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 13
                                    letterSpacing: -0.15
                                    customColor: itemRoot.isSelected ? ThemeManager.contentOnBackgroundColor : ThemeManager.contentOnBackgroundColor
                                    elideMode: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledLabel {
                                    text: {
                                        if (model.type === "cmd") return model.description
                                        if (model.type === "calc") return "Result (Enter to copy)"
                                        if (model.type === "window") return model.description
                                        if (model.type === "clip") return "Press Enter to copy snippet"
                                        if (model.type === "browser") return "Search: " + (model.description || "")
                                        return model.type === "app" ? (model.description || "Application") : "System Action"
                                    }
                                    type: "caption"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    customColor: "#8e8e93"
                                    elideMode: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            StyledLabel {
                                text: itemRoot.isSelected ? "󰁔" : ""
                                type: "icon"
                                font.pixelSize: 12
                                customColor: ThemeManager.contentOnBackgroundColor
                                visible: itemRoot.isSelected
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
