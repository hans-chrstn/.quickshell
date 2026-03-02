import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property var modelData: null
    
    implicitWidth: parent ? parent.width : 0
    implicitHeight: 44

    LazyContainer {
        id: container
        anchors.fill: parent
        active: true
        
        Item {
            id: delegateContent
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: ThemeManager.contentOnBackgroundColor
                opacity: interactionHandler.hovered ? 0.08 : 0.04
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                StyledLabel {
                    text: root.modelData ? root.modelData.pid : ""
                    type: "caption"
                    width: 80
                    opacity: 0.5
                }

                StyledLabel {
                    text: root.modelData ? root.modelData.name : ""
                    type: "body"
                    Layout.fillWidth: true
                    elideMode: Text.ElideRight
                    font.weight: Font.Medium
                }

                StyledLabel {
                    text: root.modelData ? root.modelData.cpu.toFixed(1) + "%" : "0.0%"
                    type: "caption"
                    width: 80
                    horizontalAlignment: Text.AlignRight
                    customColor: (root.modelData && root.modelData.cpu > 20) ? ThemeManager.dangerColor : ThemeManager.accentColor
                }

                StyledLabel {
                    text: root.modelData ? root.modelData.mem.toFixed(1) + "%" : "0.0%"
                    type: "caption"
                    width: 80
                    horizontalAlignment: Text.AlignRight
                }

                BaseButton {
                    width: 28
                    height: 28
                    visible: interactionHandler.hovered
                    onClicked: {
                        if (root.modelData) {
                            ProcessManager.killProcess(root.modelData.pid)
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: ThemeManager.dangerSurfaceColor
                        opacity: 0.2
                    }
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: ThemeManager.iconClose
                        type: "icon"
                        font.pixelSize: 12
                        customColor: ThemeManager.dangerColor
                    }
                }
            }

            HoverHandler {
                id: interactionHandler
            }
        }
    }
}
