import QtQuick
import qs.core

Item {
    id: root

    anchors.fill: parent

    opacity: 0.4

    readonly property int gridSpacing: 40

    Repeater {
        model: Math.ceil(root.width / (root.gridSpacing * 4)) * Math.ceil(root.height / (root.gridSpacing * 4))

        Item {
            id: nodeGroup

            readonly property int groupSpacing: root.gridSpacing * 4

            readonly property int cols: Math.ceil(root.width / groupSpacing)

            readonly property int col: index % cols

            readonly property int row: Math.floor(index / cols)

            x: col * groupSpacing

            y: row * groupSpacing

            readonly property real seed: ((col * 17) + (row * 31)) % 100

            Rectangle {
                anchors.centerIn: parent

                width: 2

                height: 2

                radius: 1

                color: "white"

                opacity: 0.4

                visible: nodeGroup.seed < 20
            }

            Item {
                width: groupSpacing

                height: 2

                anchors.verticalCenter: parent.verticalCenter

                x: 0

                visible: {
                    return nodeGroup.seed < 15 && 
                           nodeGroup.col < nodeGroup.cols - 1
                }

                Rectangle {
                    id: hPulse

                    width: 5 + (nodeGroup.seed % 10)

                    height: 1

                    color: "white"

                    opacity: 0

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: true
                        
                        PauseAnimation { 
                            duration: (nodeGroup.seed * 100) + (Math.random() * 8000) 
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: hPulse
                                property: "opacity"
                                to: 0.6
                                duration: 200
                            }

                            NumberAnimation { 
                                from: 0
                                to: nodeGroup.groupSpacing
                                duration: 800 + (Math.random() * 2000)
                                easing.type: Easing.OutCubic
                            }
                        }

                        NumberAnimation {
                            target: hPulse
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                    }
                }
            }

            Item {
                width: 2

                height: groupSpacing

                anchors.horizontalCenter: parent.horizontalCenter

                y: 0

                visible: {
                    return nodeGroup.seed > 85 && 
                           nodeGroup.row < Math.ceil(root.height / nodeGroup.groupSpacing) - 1
                }

                Rectangle {
                    id: vPulse

                    width: 1

                    height: 5 + (nodeGroup.seed % 10)

                    color: "white"

                    opacity: 0

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: true
                        
                        PauseAnimation { 
                            duration: (nodeGroup.seed * 80) + (Math.random() * 8000) 
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: vPulse
                                property: "opacity"
                                to: 0.6
                                duration: 200
                            }

                            NumberAnimation { 
                                from: 0
                                to: nodeGroup.groupSpacing
                                duration: 800 + (Math.random() * 2000)
                                easing.type: Easing.OutCubic
                            }
                        }

                        NumberAnimation {
                            target: vPulse
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                    }
                }
            }
        }
    }
}
