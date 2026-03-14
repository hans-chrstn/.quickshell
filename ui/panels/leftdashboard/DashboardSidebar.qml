import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

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

    Rectangle {
        id: navIndicator
        width: 44
        height: 44
        radius: 12
        color: ThemeManager.accentColor
        x: (parent.width - width) / 2
        y: 30 + (root.currentPage * (44 + 20))

        Behavior on y {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
        }

        z: 0
    }

    ColumnLayout {
        id: sidebarColumn
        anchors.fill: parent
        anchors.topMargin: 30
        anchors.bottomMargin: 30
        spacing: 20

        Repeater {
            model: root.pages

            delegate: BaseButton {
                Layout.alignment: Qt.AlignHCenter
                width: 44
                height: 44
                cornerRadius: 12

                readonly property var pageInfo: modelData
                tooltip: pageInfo ? pageInfo.title : ""

                onClicked: {
                    root.currentPage = index
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.cornerRadius
                    color: "transparent"
                    border.color: ThemeManager.outlinePrimaryColor
                    border.width: 1
                    visible: root.currentPage !== index
                }

                Text {
                    anchors.centerIn: parent
                    text: pageInfo ? pageInfo.icon : ""
                    color: (root.currentPage === index) 
                        ? ThemeManager.contentPrimaryColor 
                        : ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 22
                    z: 1

                    Behavior on color { 
                        ColorAnimation { duration: 250 } 
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
