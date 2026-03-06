import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import "./taskmanager"

PanelWindow {
    id: root
    
    readonly property string screenName: (root.screen) ? root.screen.name : ""
    visible: !!ViewManager.activeWindows["taskManager"] && (ViewManager.lastActiveScreenName === screenName)
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible && !closing
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function formatSpeed(bytes) {
        if (bytes > 1048576) return (bytes / 1048576).toFixed(1) + " MB/s"
        if (bytes > 1024) return (bytes / 1024).toFixed(1) + " KB/s"
        return bytes.toFixed(0) + " B/s"
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            ViewManager.closeWindow("taskManager")
        }
    }

    property bool closing: !!ViewManager.closingWindows["taskManager"]
    property bool entryActive: false
    readonly property bool showContent: visible && !closing && entryActive

    onVisibleChanged: {
        if (visible) {
            ProcessManager.startMonitoring()
            entryTimer.restart()
        } else {
            ProcessManager.stopMonitoring()
            entryActive = false
        }
    }

    Timer {
        id: entryTimer
        interval: 50
        onTriggered: {
            entryActive = true
        }
    }

    property string activeTab: "tasks"
    property bool isSidebarExpanded: true

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.shadowPrimaryColor
        opacity: root.showContent ? 0.6 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                ViewManager.closeWindowByType("taskManager")
            }
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1000
        height: 700
        anchors.centerIn: parent
        radius: 36
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1

        opacity: root.showContent ? 1.0 : 0
        scale: root.showContent ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true
            }
        }

        RowLayout {
            width: parent.width
            height: parent.height
            spacing: 0

            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: root.isSidebarExpanded ? 220 : 0
                color: Qt.rgba(0, 0, 0, 0.1)
                clip: true
                
                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutQuart
                    }
                }

                ColumnLayout {
                    width: 220
                    height: sidebar.height
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.top: parent.top
                    anchors.topMargin: 48
                    spacing: 6

                    StyledLabel {
                        text: "RESOURCE MONITOR"
                        type: "sidebarHeader"
                        opacity: 0.2
                        Layout.bottomMargin: 32
                        Layout.leftMargin: 12
                    }

                    BaseButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        onClicked: root.activeTab = "tasks"
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: parent.isHovered ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 16
                                radius: 1.5
                                color: ThemeManager.accentColor
                                visible: root.activeTab === "tasks"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                spacing: 14
                                StyledLabel {
                                    text: ThemeManager.iconTasks
                                    type: "body"
                                    font.pixelSize: 16
                                    customColor: root.activeTab === "tasks" ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                                    opacity: root.activeTab === "tasks" ? 1.0 : 0.4
                                }
                                StyledLabel {
                                    text: "Active Tasks"
                                    type: "label"
                                    font.weight: root.activeTab === "tasks" ? Font.Bold : Font.Normal
                                    font.pixelSize: 13
                                    customColor: root.activeTab === "tasks" ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                                    opacity: root.activeTab === "tasks" ? 1.0 : 0.6
                                }
                            }
                        }
                    }

                    BaseButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        onClicked: root.activeTab = "perf"
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: parent.isHovered ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 16
                                radius: 1.5
                                color: ThemeManager.accentColor
                                visible: root.activeTab === "perf"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                spacing: 14
                                StyledLabel {
                                    text: "󰄀"
                                    type: "body"
                                    font.pixelSize: 16
                                    customColor: root.activeTab === "perf" ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                                    opacity: root.activeTab === "perf" ? 1.0 : 0.4
                                }
                                StyledLabel {
                                    text: "Performance"
                                    type: "label"
                                    font.weight: root.activeTab === "perf" ? Font.Bold : Font.Normal
                                    font.pixelSize: 13
                                    customColor: root.activeTab === "perf" ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                                    opacity: root.activeTab === "perf" ? 1.0 : 0.6
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                Rectangle {
                    anchors.right: parent.right
                    height: parent.height
                    width: 1
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.05
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    Layout.leftMargin: 48
                    Layout.rightMargin: 48
                    spacing: 0
                    
                    TaskManagerHeader { 
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        isSidebarExpanded: root.isSidebarExpanded
                        onToggleSidebar: root.isSidebarExpanded = !root.isSidebarExpanded
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.05
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 40
                        anchors.topMargin: 32
                        anchors.bottomMargin: 32
                        visible: root.activeTab === "tasks"
                        spacing: 24

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 32
                            Layout.leftMargin: 12
                            
                            RowLayout {
                                spacing: 8
                                StyledLabel { text: "CPU"; type: "caption"; font.weight: Font.Black; opacity: 0.3 }
                                StyledLabel { 
                                    text: Math.round(ProcessManager.cpuUsage) + "%"
                                    type: "body"; font.weight: Font.Bold; customColor: ThemeManager.accentColor 
                                }
                            }
                            RowLayout {
                                spacing: 8
                                StyledLabel { text: "MEM"; type: "caption"; font.weight: Font.Black; opacity: 0.3 }
                                StyledLabel { 
                                    text: Math.round(ProcessManager.memUsage) + "%"
                                    type: "body"; font.weight: Font.Bold; customColor: ThemeManager.surfaceContentColor
                                }
                            }
                            RowLayout {
                                spacing: 8
                                StyledLabel { text: "NET UP"; type: "caption"; font.weight: Font.Black; opacity: 0.3 }
                                StyledLabel { 
                                    text: root.formatSpeed(ProcessManager.netUp)
                                    type: "body"; font.weight: Font.Bold; customColor: ThemeManager.surfaceContentColor
                                }
                            }
                        }

                        ListView {
                            id: processList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: ProcessManager.model
                            spacing: 4
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            header: Item {
                                width: processList.width
                                height: 40
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    
                                    StyledLabel {
                                        text: "PID"
                                        type: "caption"
                                        width: 80
                                        opacity: 0.4
                                    }
                                    StyledLabel {
                                        text: "NAME"
                                        type: "caption"
                                        width: 400
                                        opacity: 0.4
                                    }
                                    StyledLabel {
                                        text: "CPU %"
                                        type: "caption"
                                        width: 80
                                        horizontalAlignment: Text.AlignRight
                                        opacity: 0.4
                                    }
                                    StyledLabel {
                                        text: "MEM %"
                                        type: "caption"
                                        width: 80
                                        horizontalAlignment: Text.AlignRight
                                        opacity: 0.4
                                    }
                                }
                            }

                            delegate: TaskManagerListDelegate {
                                width: processList.width
                                height: 44
                                modelData: model
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 40
                        anchors.topMargin: 32
                        visible: root.activeTab === "perf"
                        spacing: 32

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                StyledLabel { text: "CPU LOAD HISTORY"; type: "caption"; font.weight: Font.Black; opacity: 0.25; letterSpacing: 2; Layout.leftMargin: 4 }
                                Item { Layout.fillWidth: true }
                                StyledLabel { 
                                    text: Math.round(ProcessManager.cpuUsage) + "%"
                                    type: "body"; font.weight: Font.Bold; customColor: ThemeManager.accentColor 
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                Rectangle { anchors.fill: parent; radius: 16; color: ThemeManager.contentOnBackgroundColor; opacity: 0.03 }
                                SparklineGraph {
                                    anchors.fill: parent; anchors.margins: 15
                                    dataHistory: ProcessManager.cpuHistory
                                    lineColor: ThemeManager.accentColor
                                    maxValue: 100
                                    autoScale: false
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                StyledLabel { text: "MEMORY USAGE HISTORY"; type: "caption"; font.weight: Font.Black; opacity: 0.25; letterSpacing: 2; Layout.leftMargin: 4 }
                                Item { Layout.fillWidth: true }
                                StyledLabel { 
                                    text: Math.round(ProcessManager.memUsage) + "%"
                                    type: "body"; font.weight: Font.Bold; customColor: "#55FF55"
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                Rectangle { anchors.fill: parent; radius: 16; color: ThemeManager.contentOnBackgroundColor; opacity: 0.03 }
                                SparklineGraph {
                                    anchors.fill: parent; anchors.margins: 15
                                    dataHistory: ProcessManager.memHistory
                                    lineColor: "#55FF55"
                                    maxValue: 100
                                    autoScale: false
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                StyledLabel { text: "NETWORK THROUGHPUT (UPLOAD)"; type: "caption"; font.weight: Font.Black; opacity: 0.25; letterSpacing: 2; Layout.leftMargin: 4 }
                                Item { Layout.fillWidth: true }
                                StyledLabel { 
                                    text: root.formatSpeed(ProcessManager.netUp)
                                    type: "body"; font.weight: Font.Bold; customColor: "#55AAFF"
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                Rectangle { anchors.fill: parent; radius: 16; color: ThemeManager.contentOnBackgroundColor; opacity: 0.03 }
                                SparklineGraph {
                                    anchors.fill: parent; anchors.margins: 15
                                    dataHistory: ProcessManager.netUpHistory
                                    lineColor: "#55AAFF"
                                    maxValue: 10485760
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
