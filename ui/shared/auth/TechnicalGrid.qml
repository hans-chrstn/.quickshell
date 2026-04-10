import QtQuick
import qs.core

Item {
    id: root

    anchors.fill: parent

    opacity: 0.2

    readonly property int gridSpacing: 40

    readonly property int thickness: 2

    Repeater {
        model: Math.ceil(root.width / root.gridSpacing)

        Rectangle {
            x: index * root.gridSpacing

            y: 0

            width: root.thickness

            height: root.height
            
            gradient: Gradient {
                GradientStop { 
                    position: 0.0
                    color: "transparent" 
                }
                GradientStop { 
                    position: 0.2 + (Math.random() * 0.1)
                    color: ThemeManager.accentColor 
                }
                GradientStop { 
                    position: 0.8 - (Math.random() * 0.1)
                    color: ThemeManager.accentColor 
                }
                GradientStop { 
                    position: 1.0
                    color: "transparent" 
                }
            }

            opacity: {
                if (index % 4 === 0) {
                    return 0.6
                }
                return 0.2
            }

            anchors {
                topMargin: Math.random() * 50
                bottomMargin: Math.random() * 50
            }
        }
    }

    Repeater {
        model: Math.ceil(root.height / root.gridSpacing)

        Rectangle {
            x: 0

            y: index * root.gridSpacing

            width: root.width

            height: root.thickness
            
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { 
                    position: 0.0
                    color: "transparent" 
                }
                GradientStop { 
                    position: 0.2 + (Math.random() * 0.1)
                    color: ThemeManager.accentColor 
                }
                GradientStop { 
                    position: 0.8 - (Math.random() * 0.1)
                    color: ThemeManager.accentColor 
                }
                GradientStop { 
                    position: 1.0
                    color: "transparent" 
                }
            }

            opacity: {
                if (index % 4 === 0) {
                    return 0.6
                }
                return 0.2
            }

            anchors {
                leftMargin: Math.random() * 50
                rightMargin: Math.random() * 50
            }
        }
    }
}
