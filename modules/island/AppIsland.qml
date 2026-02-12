import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

Item {
    id: root

    property int barHeight: FrameConfig.thickness
    property color barColor: FrameConfig.color
    property string searchText: ""

    property bool expanded: false

    states: [
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: root; width: FrameConfig.appIslandExpandedWidth; height: FrameConfig.appIslandExpandedHeight }
            PropertyChanges { target: islandContentArea; opacity: 1 }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandCollapsedWidth; height: root.barHeight }
            PropertyChanges { target: islandContentArea; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            from: "collapsed"
            to: "expanded"
            NumberAnimation {
                properties: "width,height"
                duration: FrameConfig.animDuration
                easing.type: Easing.OutExpo
            }
            SequentialAnimation {
                PauseAnimation { duration: FrameConfig.animDuration * 0.5 }
                NumberAnimation {
                    target: islandContentArea
                    property: "opacity"
                    duration: FrameConfig.animDuration * 0.5
                }
            }
        },
        Transition {
            from: "expanded"
            to: "collapsed"
            NumberAnimation {
                properties: "width,height"
                duration: FrameConfig.animDuration
                easing.type: Easing.InExpo
            }
            NumberAnimation {
                target: islandContentArea
                property: "opacity"
                duration: FrameConfig.animDuration * 0.5
            }
        }
    ]

    Item {
        id: islandContainer
        anchors.fill: parent

        RoundedCornerShape {
            anchors.right: islandRect.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth
            height: Math.min(FrameConfig.roundedCornerShapeWidth, Math.max(0, root.height - root.barHeight))
            isLeft: true
            isBottom: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            visible: root.height > (root.barHeight + 2)
        }

        RoundedCornerShape {
            anchors.left: islandRect.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth
            height: Math.min(FrameConfig.roundedCornerShapeWidth, Math.max(0, root.height - root.barHeight))
            isLeft: false
            isBottom: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            visible: root.height > (root.barHeight + 2)
        }

        ClippingRectangle {
            id: islandRect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.barColor

            states: [
                State {
                    name: "expanded"
                    when: root.expanded
                    PropertyChanges {
                        target: islandRect;
                        topLeftRadius: FrameConfig.dynamicIslandCornerRadius;
                        topRightRadius: FrameConfig.dynamicIslandCornerRadius;
                        bottomLeftRadius: 0;
                        bottomRightRadius: 0
                    }
                },
                State {
                    name: "collapsed"
                    when: !root.expanded
                    PropertyChanges {
                        target: islandRect;
                        topLeftRadius: 0;
                        topRightRadius: 0;
                        bottomLeftRadius: 0;
                        bottomRightRadius: 0
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "collapsed"
                    to: "expanded"
                    NumberAnimation {
                        properties: "topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius"
                        duration: FrameConfig.animDuration
                        easing.type: Easing.OutExpo
                    }
                },
                Transition {
                    from: "expanded"
                    to: "collapsed"
                    NumberAnimation {
                        properties: "topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius"
                        duration: FrameConfig.animDuration
                        easing.type: Easing.InExpo
                    }
                }
            ]

            Item {
                id: islandContentArea
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 20
                        color: "#333333"

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: "white"
                            font.pixelSize: 16
                            onTextChanged: {
                                root.searchText = text
                            }
                            Keys.onUpPressed: appListView.decrementCurrentIndex()
                            Keys.onDownPressed: appListView.incrementCurrentIndex()
                            Keys.onReturnPressed: {
                                if (appListView.currentItem && appListView.currentItem.modelData) {
                                    appListView.currentItem.modelData.execute()
                                }
                            }
                            Keys.onPressed: event => {
                                if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z ||
                                    event.key >= Qt.Key_0 && event.key <= Qt.Key_9 ||
                                    event.key >= Qt.Key_Space && event.key <= Qt.Key_AsciiTilde ||
                                    event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                                    searchInput.forceActiveFocus()
                                }
                            }
                            Connections {
                                target: root
                                function onExpandedChanged() {
                                    if (root.expanded) {
                                        searchInput.forceActiveFocus()
                                    } else {
                                        searchInput.text = ""
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            text: "Search applications..."
                            color: "#888888"
                            font.pixelSize: 16
                            visible: !searchInput.text && !searchInput.activeFocus
                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchInput.forceActiveFocus()
                            }
                        }
                    }

                    ListView {
                        id: appListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 5
                        
                        model: ScriptModel {
                            values: {
                                var filteredApps = DesktopEntries.applications.values.filter(function(app) {
                                    return app.name.toLowerCase().includes(root.searchText.toLowerCase()) ||
                                           app.keywords.join(" ").toLowerCase().includes(root.searchText.toLowerCase());
                                });
                                return filteredApps;
                            }
                        }

                        delegate: Item {
                            width: appListView.width
                            height: 40

                            Rectangle {
                                anchors.fill: parent
                                color: appListView.currentIndex === index ? "#555555" : "transparent"
                                radius: 5
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 10

                                Image {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    source: Quickshell.iconPath(modelData.icon)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData.name
                                    color: "white"
                                    font.pixelSize: 16
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    modelData.execute()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
