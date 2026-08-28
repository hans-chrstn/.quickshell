import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.core
import qs.core.auth
import qs.ui.shared

Item {
    id: root

    implicitWidth: 440

    implicitHeight: 160

    visible: AuthManager.currentUser !== ""

    property real expandWidth: 0

    property real expandHeight: 0

    property bool active: false

    onVisibleChanged: {
        if (visible) {
            introAnim.start()
        } else {
            root.expandWidth = 0
            root.expandHeight = 0
        }
    }

    SequentialAnimation {
        id: introAnim

        NumberAnimation {
            target: root
            property: "expandWidth"
            to: 1
            duration: 400
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "expandHeight"
            to: 1
            duration: 500
            easing.type: Easing.OutQuart
        }
    }

    Rectangle {
        id: container

        anchors.centerIn: parent

        width: 440 * root.expandWidth

        height: 160 * root.expandHeight

        color: Qt.rgba(0, 0, 0, 0.4)

        border {
            color: ThemeManager.outlinePrimaryColor
            width: 1
        }

        clip: true

        opacity: {
            if (root.expandHeight > 0.1) {
                return 1
            }
            return 0
        }

        Behavior on opacity {
            NumberAnimation { 
                duration: 200 
            }
        }

        Rectangle { 
            width: 10
            height: 1
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return root.expandWidth > 0.9
            }

            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 1
            height: 10
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return root.expandHeight > 0.9
            }

            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 10
            height: 1
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return root.expandWidth > 0.9
            }

            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        Rectangle { 
            width: 1
            height: 10
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return root.expandHeight > 0.9
            }

            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        RowLayout {
            anchors {
                fill: parent
                margins: 24
            }

            spacing: 24

            opacity: {
                if (root.expandHeight > 0.8) {
                    return 1
                }
                return 0
            }

            Behavior on opacity {
                NumberAnimation { 
                    duration: 300 
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 20

                    Column {
                        StyledLabel {
                            text: "EMPID //"
                            font { 
                                pixelSize: 10
                                weight: Font.Black 
                            }
                            opacity: 0.5
                        }
                        StyledLabel {
                            text: AuthManager.userUuid
                            font { 
                                pixelSize: 16
                                family: "monospace" 
                            }
                            customColor: ThemeManager.accentColor
                        }
                    }

                    Column {
                        StyledLabel {
                            text: "CLASS //"
                            font { 
                                pixelSize: 10
                                weight: Font.Black 
                            }
                            opacity: 0.5
                        }
                        StyledLabel {
                            text: "OPERATOR"
                            font { 
                                pixelSize: 16
                                family: "monospace" 
                            }
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.topMargin: 5

                    StyledLabel {
                        text: "NAME //"
                        font { 
                            pixelSize: 10
                            weight: Font.Black 
                        }
                        opacity: 0.5
                    }

                    StyledLabel {
                        width: parent.width
                        text: {
                            if (AuthManager.currentUser !== "") {
                                return AuthManager.currentUser.toUpperCase()
                            }
                            return "AWAITING_IDENT..."
                        }
                        font { 
                            pixelSize: 22
                            weight: Font.Black 
                        }
                        elideMode: Text.ElideRight
                    }
                }

                Item { 
                    Layout.fillHeight: true 
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    color: "transparent"

                    Row {
                        anchors.fill: parent
                        spacing: 2

                        Repeater {
                            model: 30
                            Rectangle {
                                width: (index % 4 == 0) ? 3 : 1
                                height: parent.height
                                color: ThemeManager.surfaceContentColor
                                opacity: (index / 30) * 0.4
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.5)
                
                border { 
                    color: ThemeManager.outlinePrimaryColor
                    width: 1 
                }
                
                clip: true

                HandshakeRing {
                    anchors.centerIn: parent
                    active: root.active
                }

                Fingerprint {
                    anchors.centerIn: parent
                    width: 100
                    height: 100
                    opacity: 0.8
                    active: root.active
                }

                Rectangle {
                    id: scanLine
                    width: parent.width
                    height: 2
                    color: ThemeManager.accentColor
                    
                    opacity: {
                        if (AuthManager.state === AuthManager.State.Loading) {
                            return 0.8
                        }
                        return 0
                    }

                    SequentialAnimation on y {
                        running: AuthManager.state === AuthManager.State.Loading
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: 160; duration: 2000 }
                    }
                }
            }
        }
    }
}
