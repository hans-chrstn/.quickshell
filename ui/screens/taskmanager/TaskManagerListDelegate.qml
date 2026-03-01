import QtQuick
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: delegateWrapper
    
    property var modelData
    
    LazyLoader {
        id: cardLdr
        property var proc: delegateWrapper.modelData
        
        loading: true
        activeAsync: true
        
        component: Component {
            Rectangle {
                radius: 12
                color: hHover.hovered ? ThemeManager.surfacePrimaryColor : ThemeManager.surfaceSubtleColor
                border.color: ThemeManager.outlinePrimaryColor
                border.width: 1
                
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    
                    StyledLabel {
                        text: cardLdr.proc ? cardLdr.proc.pid : ""
                        type: "monospace"
                        width: 80
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledLabel {
                        text: cardLdr.proc ? cardLdr.proc.name : ""
                        type: "body"
                        font.weight: Font.Bold
                        width: 600
                        elideMode: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledLabel {
                        text: cardLdr.proc ? cardLdr.proc.cpu.toFixed(1) + "%" : ""
                        type: "monospace"
                        width: 80
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        customColor: (cardLdr.proc && cardLdr.proc.cpu > 50) ? ThemeManager.dangerPrimaryColor : ThemeManager.contentOnBackgroundColor
                    }
                    
                    StyledLabel {
                        text: cardLdr.proc ? cardLdr.proc.mem.toFixed(1) + "%" : ""
                        type: "monospace"
                        width: 80
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    BaseButton {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            if (cardLdr.proc) {
                                ProcessManager.killProcess(cardLdr.proc.pid)
                            }
                        }
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "󰆴"
                            type: "icon"
                            font.pixelSize: 14
                            opacity: parent.isHovered ? 1.0 : 0.2
                            customColor: ThemeManager.dangerPrimaryColor
                        }
                    }
                }
                
                HoverHandler {
                    id: hHover
                }
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
