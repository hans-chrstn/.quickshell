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

    property real expansion: visible ? 1 : 0

    Rectangle {
        id: container

        anchors.centerIn: parent

        width: 440 * root.expansion

        height: 160 * root.expansion

        color: Qt.rgba(0, 0, 0, 0.4)

        border {
            color: ThemeManager.outlinePrimaryColor
            width: 1
        }

        clip: true

        opacity: root.expansion

        Behavior on width {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        Rectangle { 
            width: 10
            height: 1
            color: ThemeManager.accentColor
            z: 20

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

                Image {
                    id: avatarImg

                    anchors {
                        fill: parent
                        margins: 1
                    }

                    source: {
                        if (AuthManager.currentUser !== "") {
                            return "file:///var/lib/AccountsService/icons/" + AuthManager.currentUser
                        }
                        return ""
                    }

                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.8
                    visible: status === Image.Ready

                    onStatusChanged: {
                        if (status === Image.Error && AuthManager.currentUser !== "") {
                            source = "file:///usr/share/icons/hicolor/scalable/apps/user-available.svg"
                        }
                    }
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
