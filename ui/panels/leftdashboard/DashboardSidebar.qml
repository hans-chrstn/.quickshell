import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import "./sidebar"

Rectangle {
    id: sidebarRoot

    Layout.fillHeight: true
    Layout.preferredWidth: 70
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop { 
                position: 0.0 
                color: ThemeManager.surfaceSubtleColor 
            }

            GradientStop { 
                position: 0.8 
                color: Qt.rgba(0, 0, 0, 0.15) 
            }

            GradientStop { 
                position: 1.0 
                color: "transparent" 
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: ThemeManager.outlineVariantColor
        opacity: 0.5
    }

    SelectionPill {
        id: navIndicator
        width: 44
        height: 44
        radius: 12
        x: {
            return (parent.width - width) / 2
        }
        y: {
            return 30 + (root.currentPage * (44 + 20))
        }
    }

    ColumnLayout {
        id: sidebarColumn
        anchors.fill: parent
        anchors.topMargin: 30
        anchors.bottomMargin: 30
        spacing: 20

        Repeater {
            model: {
                return root.pages
            }

            delegate: SidebarItem {
                pageInfo: modelData
                isSelected: {
                    return root.currentPage === index
                }
                onSelected: {
                    root.currentPage = index
                }
            }
        }

        Item { 
            Layout.fillHeight: true 
        }
    }
}
