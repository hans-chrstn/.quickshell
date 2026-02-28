import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors { left: true; right: true; top: true; bottom: true }
    
    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool entryStarted: false
    onVisibleChanged: {
        if (visible) {
            ProcessManager.startMonitoring()
            Qt.callLater(() => { entryStarted = true })
        } else {
            ProcessManager.stopMonitoring()
            entryStarted = false
        }
    }

    Rectangle {
        anchors.fill: parent; color: ThemeManager.shadowPrimaryColor
        opacity: root.entryStarted ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: ViewManager.closeWindowByType("taskManager") }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1000; height: 700
        anchors.centerIn: parent; radius: 36
        color: ThemeManager.backgroundPrimaryColor; border.color: ThemeManager.outlinePrimaryColor; border.width: 1
        
        opacity: root.entryStarted ? 1.0 : 0
        scale: root.entryStarted ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 32; spacing: 24

            RowLayout {
                Layout.fillWidth: true; spacing: 16
                StyledLabel { text: "󰍛"; type: "heading"; customColor: ThemeManager.accentColor; font.pixelSize: 32 }
                ColumnLayout {
                    spacing: 0
                    StyledLabel { text: "SYSTEM TASKS"; type: "controlPanelHeader" }
                    StyledLabel { text: "RESOURCE MONITOR"; type: "caption"; opacity: 0.4; font.weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                
                Row {
                    spacing: 8
                    Repeater {
                        model: ["cpu", "mem", "pid", "name"]
                        delegate: Rectangle {
                            width: 60; height: 28; radius: 14
                            color: ProcessManager.sortBy === modelData ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
                            opacity: ProcessManager.sortBy === modelData ? 1.0 : 0.5
                            StyledLabel { anchors.centerIn: parent; text: modelData.toUpperCase(); type: "caption"; font.weight: Font.Black; customColor: ProcessManager.sortBy === modelData ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor }
                            TapHandler { onTapped: ProcessManager.sortBy = modelData }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                BaseButton {
                    width: 36; height: 36
                    onClicked: ViewManager.closeWindowByType("taskManager")
                    Rectangle { anchors.fill: parent; radius: 18; color: ThemeManager.surfacePrimaryColor; StyledLabel { anchors.centerIn: parent; text: "󰅖"; type: "icon" } }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: ThemeManager.contentOnBackgroundColor; opacity: 0.05 }

            ListView {
                id: processList
                Layout.fillWidth: true; Layout.fillHeight: true
                model: ProcessManager.model
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                header: Item {
                    width: processList.width; height: 30
                    Row {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                        StyledLabel { text: "PID"; type: "caption"; width: 80; opacity: 0.4 }
                        StyledLabel { text: "NAME"; type: "caption"; width: 600; opacity: 0.4 }
                        StyledLabel { text: "CPU %"; type: "caption"; width: 80; horizontalAlignment: Text.AlignRight; opacity: 0.4 }
                        StyledLabel { text: "MEM %"; type: "caption"; width: 80; horizontalAlignment: Text.AlignRight; opacity: 0.4 }
                    }
                }

                delegate: Item {
                    id: delegateWrapper
                    width: processList.width; height: 44
                    
                    LazyLoader {
                        id: cardLdr
                        property var proc: model
                        
                        loading: true
                        activeAsync: true
                        
                        component: Component {
                            Rectangle {
                                radius: 12
                                color: hHover.hovered ? ThemeManager.surfacePrimaryColor : ThemeManager.surfaceSubtleColor
                                border.color: ThemeManager.outlinePrimaryColor; border.width: 1
                                
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    StyledLabel { 
                                        text: cardLdr.proc ? cardLdr.proc.pid : ""
                                        type: "monospace"; width: 80; anchors.verticalCenter: parent.verticalCenter 
                                    }
                                    StyledLabel { 
                                        text: cardLdr.proc ? cardLdr.proc.name : ""
                                        type: "body"; font.weight: Font.Bold; width: 600; elideMode: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter 
                                    }
                                    StyledLabel { 
                                        text: cardLdr.proc ? cardLdr.proc.cpu.toFixed(1) + "%" : ""
                                        type: "monospace"; width: 80; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter; 
                                        customColor: (cardLdr.proc && cardLdr.proc.cpu > 50) ? ThemeManager.dangerPrimaryColor : ThemeManager.contentOnBackgroundColor 
                                    }
                                    StyledLabel { 
                                        text: cardLdr.proc ? cardLdr.proc.mem.toFixed(1) + "%" : ""
                                        type: "monospace"; width: 80; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter 
                                    }
                                    
                                    BaseButton {
                                        width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                                        onClicked: if (cardLdr.proc) ProcessManager.killProcess(cardLdr.proc.pid)
                                        StyledLabel { anchors.centerIn: parent; text: "󰆴"; type: "icon"; font.pixelSize: 14; opacity: parent.isHovered ? 1.0 : 0.2; customColor: ThemeManager.dangerPrimaryColor }
                                    }
                                }
                                HoverHandler { id: hHover }
                            }
                        }

                        onItemChanged: {
                            if (item) {
                                item.parent = delegateWrapper
                                item.anchors.fill = delegateWrapper
                            }
                        }
                    }
                }
            }
        }
    }
}
