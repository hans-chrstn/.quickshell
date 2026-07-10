import QtQuick
import QtQuick.Effects
import qs.core
import qs.ui.shared

Item {
    id: root

    property var activeConfig: []
    property int selectedIndex: -1
    property real centerX: 0
    property real centerY: 0
    property real currentX: 0
    property real currentY: 0
    property bool readyToDraw: false
    property var availablePages: []
    property int currentPageIndex: 0

    signal actionTriggered(var item)

    opacity: readyToDraw ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Item {
        id: stripContainer
        x: root.centerX - width / 2
        y: root.centerY - height / 2 + 40
        width: pillStrip.width + 28
        height: 46

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: ThemeManager.backgroundPrimaryColor
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 23
            color: ThemeManager.backgroundPrimaryColor
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 23
            color: "transparent"
            border.color: ThemeManager.outlineStrongColor
            border.width: 1
        }

        Row {
            id: pillStrip
            anchors.centerIn: parent
            spacing: 6

            StyledLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁅"
                type: "icon"
                font.pixelSize: 16
                opacity: root.currentPageIndex > 0 ? 0.4 : 0.1
                visible: root.availablePages.length > 1
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }

            Repeater {
                model: root.activeConfig

                delegate: Item {
                    width: activePill.width
                    height: 42
                    anchors.verticalCenter: parent.verticalCenter
                    property bool isSelected: index === root.selectedIndex

                    Rectangle {
                        id: activePill
                        anchors.verticalCenter: parent.verticalCenter
                        height: isSelected ? 34 : 28
                        width: isSelected ? rowLayout.implicitWidth + 24 : 28
                        radius: height / 2
                        color: isSelected ? ThemeManager.accentColor : "#25282e"
                        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        layer.enabled: isSelected
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowOpacity: 0.3
                            shadowBlur: 0.4
                            shadowVerticalOffset: 4
                        }

                        Row {
                            id: rowLayout
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            StyledLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                type: "icon"
                                font.pixelSize: 18
                                customColor: isSelected ? "#111111" : ThemeManager.contentOnBackgroundColor
                            }

                            StyledLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                type: "body"
                                font.weight: Font.DemiBold
                                font.pixelSize: 12
                                letterSpacing: -0.15
                                customColor: isSelected ? "#111111" : ThemeManager.contentOnBackgroundColor
                                visible: isSelected
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedIndex = index
                                root.actionTriggered(activePill)
                            }
                        }
                    }
                }
            }

            StyledLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁔"
                type: "icon"
                font.pixelSize: 16
                opacity: root.currentPageIndex < (root.availablePages.length - 1) ? 0.4 : 0.1
                visible: root.availablePages.length > 1
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
