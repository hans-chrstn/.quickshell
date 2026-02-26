import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import qs.core
import qs.ui.shared
import qs.ui.screens.lock

PanelWindow {
    id: root
    
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    color: "black"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    focusable: true
    
    Shortcut {
        sequence: "Shift+Alt+E"
        onActivated: Qt.quit()
    }

    property bool isAuthenticated: false
    property bool isUserSelected: Greetd.user !== ""
    
    property real mouseX: 0
    property real mouseY: 0

    readonly property string lastUserCachePath: Quickshell.cachePath("last_user")
    
    FileView {
        id: lastUserFile
        path: root.lastUserCachePath
        onLoaded: {
            let lastUser = text().trim()
            if (lastUser && !root.isUserSelected) {
                mainContentRect.usernameBuffer = lastUser
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            mainContentRect.forceActiveFocus()
        }
    }

    Rectangle {
        id: mainContentRect
        anchors.fill: parent
        color: "black"
        focus: true
        
        onActiveFocusChanged: if (!activeFocus && !showSessionPicker) mainContentRect.forceActiveFocus()
        Component.onCompleted: mainContentRect.forceActiveFocus()

        property string usernameBuffer: ""
        property string passwordBuffer: ""
        property string statusMessage: "Enter Username"
        property bool isErrorMessage: false
        property bool showSessionPicker: false

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                root.mouseX = (mouse.x - width / 2) / (width / 2)
                root.mouseY = (mouse.y - height / 2) / (height / 2)
            }
            onClicked: mainContentRect.showSessionPicker = false
        }

        Keys.onPressed: (event) => {
            if (mainContentRect.showSessionPicker) return

            if (event.text.length === 1 || event.key === Qt.Key_Backspace) {
                SoundManager.playClick()
            }
            
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (!root.isUserSelected) {
                    if (usernameBuffer.length > 0) {
                        Greetd.createSession(usernameBuffer)
                        statusMessage = "Authenticating..."
                        isErrorMessage = false
                    }
                } else {
                    Greetd.respond(passwordBuffer)
                    passwordBuffer = ""
                }
            } else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    if (!root.isUserSelected) usernameBuffer = ""
                    else passwordBuffer = ""
                } else {
                    if (!root.isUserSelected) usernameBuffer = usernameBuffer.slice(0, -1)
                    else passwordBuffer = passwordBuffer.slice(0, -1)
                }
            } else if (event.key === Qt.Key_Escape) {
                if (root.isUserSelected) {
                    Greetd.cancelSession()
                    passwordBuffer = ""
                    statusMessage = "Enter Username"
                    isErrorMessage = false
                }
            } else if (event.text.length === 1 && event.text !== "\r" && event.text !== "\n") {
                if (!root.isUserSelected) usernameBuffer += event.text
                else passwordBuffer += event.text
            }
        }

        Connections {
            target: Greetd
            function onAuthMessage(message, isError, responseRequired, echoResponse) {
                if (message) {
                    if (message.toLowerCase().includes("password")) {
                        mainContentRect.statusMessage = "Enter Password"
                    } else {
                        mainContentRect.statusMessage = message
                    }
                    mainContentRect.isErrorMessage = isError
                }
            }
            
            function onAuthFailure(message) {
                mainContentRect.passwordBuffer = ""
                mainContentRect.statusMessage = message || "Authentication failed"
                mainContentRect.isErrorMessage = true
                SoundManager.playCollapse()
            }
            
            function onReadyToLaunch() {
                root.isAuthenticated = true
                SoundManager.playSuccess()
                lastUserFile.setText(Greetd.user)
                launchTimer.start()
            }
            
            function onError(error) {
                mainContentRect.statusMessage = error
                mainContentRect.isErrorMessage = true
            }
        }

        Timer {
            id: launchTimer
            interval: 600
            onTriggered: {
                let cmdString = SessionManager.currentSessionExec
                if (cmdString === "") {
                    Greetd.launch([])
                } else {
                    let cmd = cmdString.match(/[^\s"']+|"([^"]*)"|'([^']*)'/g).map(arg => {
                        if (arg.startsWith('"') || arg.startsWith("'")) return arg.slice(1, -1)
                        return arg
                    })
                    Greetd.launch(cmd)
                }
            }
        }

        LockScreenBackground {
            id: background
            relativeMouseX: root.mouseX
            relativeMouseY: root.mouseY
        }

        LockScreenStatusBar {
            opacity: contentContainer.opacity
        }

        Item {
            id: contentContainer
            anchors.centerIn: parent
            width: innerLayout.implicitWidth
            height: innerLayout.implicitHeight
            
            transform: Translate {
                x: root.mouseX * (ThemeManager.lockParallaxIntensity / 2)
                y: root.mouseY * (ThemeManager.lockParallaxIntensity / 2)
                Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }

            ColumnLayout {
                id: innerLayout
                anchors.centerIn: parent
                spacing: ThemeManager.lockContentSpacing
                
                LockScreenClock { }

                ColumnLayout {
                    spacing: 25
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        spacing: 15
                        Layout.alignment: Qt.AlignHCenter
                        
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 100; height: 100
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 50
                                color: Qt.rgba(1, 1, 1, 0.05)
                                border.color: ColorManager.accentColor
                                border.width: 1
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰀉"
                                    font.pixelSize: 44
                                    color: ThemeManager.contentOnBackgroundColor
                                    opacity: 0.8
                                }
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 50
                                color: "transparent"
                                border.color: ThemeManager.accentColor
                                border.width: 2
                                visible: root.isUserSelected
                                scale: root.isUserSelected ? 1.1 : 1.0
                                opacity: root.isUserSelected ? 0.5 : 0
                                Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                                Behavior on opacity { NumberAnimation { duration: 400 } }
                            }
                        }

                        Text {
                            id: userDisplayLabel
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isUserSelected ? Greetd.user.toUpperCase() : (mainContentRect.usernameBuffer || "TYPE USERNAME").toUpperCase()
                            color: ThemeManager.contentOnBackgroundColor
                            font.pixelSize: 18
                            font.weight: Font.Black
                            font.letterSpacing: 2
                            opacity: mainContentRect.usernameBuffer || root.isUserSelected ? 0.9 : 0.2
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    Rectangle {
                        id: inputFieldContainer
                        width: 320; height: 54; radius: 27
                        color: Qt.rgba(1, 1, 1, ThemeManager.lockPasswordOpacity)
                        border.color: mainContentRect.isErrorMessage ? ThemeManager.dangerColor : Qt.rgba(ColorManager.accentColor.r, ColorManager.accentColor.g, ColorManager.accentColor.b, 0.2)
                        border.width: 1
                        
                        Item {
                            anchors.fill: parent
                            
                            Row {
                                id: passwordDotRow
                                anchors.centerIn: parent; spacing: 10
                                visible: root.isUserSelected
                                Repeater {
                                    model: mainContentRect.passwordBuffer.length
                                    Rectangle {
                                        width: 10; height: 10; radius: 5; color: ColorManager.accentColor
                                        NumberAnimation on scale { from: 0; to: 1; duration: 150; easing.type: Easing.OutBack }
                                    }
                                }
                            }

                            Text {
                                id: usernameDisplayLabel
                                anchors.centerIn: parent
                                visible: !root.isUserSelected
                                text: mainContentRect.usernameBuffer
                                color: ThemeManager.contentOnBackgroundColor
                                font.pixelSize: 16; font.weight: Font.Medium
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: root.isUserSelected ? (mainContentRect.passwordBuffer.length === 0 ? "PASSWORD" : "") : ""
                                color: ThemeManager.contentOnBackgroundColor
                                opacity: 0.2; font.pixelSize: 12; font.weight: Font.Black; font.letterSpacing: 1
                            }

                            Rectangle {
                                id: caretVisual
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: {
                                    if (!root.isUserSelected && mainContentRect.usernameBuffer.length > 0) {
                                        return (usernameDisplayLabel.implicitWidth / 2) + 4
                                    }
                                    return 0
                                }
                                visible: (!root.isUserSelected && mainContentRect.usernameBuffer.length === 0) || (root.isUserSelected && mainContentRect.passwordBuffer.length === 0)
                                width: 2
                                height: 20
                                color: ColorManager.accentColor
                                
                                SequentialAnimation on opacity { 
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0; duration: 500 }
                                    NumberAnimation { to: 1; duration: 500 } 
                                }
                            }
                        }
                    }
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15
                        opacity: 0.3
                        
                        Text {
                            text: root.isUserSelected ? "󰌾  ESC TO CHANGE USER" : "󰌾  ENTER TO SELECT"
                            color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 8; font.weight: Font.Bold; font.letterSpacing: 1
                        }
                    }

                    BaseButton {
                        Layout.alignment: Qt.AlignHCenter
                        width: 320; height: 30
                        onClicked: mainContentRect.showSessionPicker = !mainContentRect.showSessionPicker
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(1, 1, 1, 0.05)
                            radius: 15
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                Text {
                                    text: "󰊠  " + SessionManager.currentSessionName.toUpperCase()
                                    color: ThemeManager.contentOnBackgroundColor
                                    font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1
                                    opacity: 0.6
                                }
                                Text {
                                    text: "󱗘"
                                    color: ColorManager.accentColor
                                    font.pixelSize: 10
                                    opacity: 0.8
                                }
                            }
                        }
                    }
                }
                
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 350
                    Layout.preferredHeight: 30
                    
                    Text {
                        anchors.centerIn: parent
                        text: mainContentRect.statusMessage.toUpperCase()
                        color: mainContentRect.isErrorMessage ? ThemeManager.dangerColor : ThemeManager.accentColor
                        font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1.5
                        opacity: text ? 0.8 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.95)
            visible: mainContentRect.showSessionPicker
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 30
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "SESSION MANAGEMENT"
                    color: ColorManager.accentColor
                    font.pixelSize: 16; font.weight: Font.Black; font.letterSpacing: 3
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 150; height: 36; radius: 18
                            color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1)
                            TextInput {
                                id: newSessionName
                                anchors.fill: parent; anchors.margins: 10
                                color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                                clip: true
                                Text { text: "NAME"; visible: !parent.text; color: "gray"; font.pixelSize: 10; anchors.centerIn: parent }
                            }
                        }
                        Rectangle {
                            width: 250; height: 36; radius: 18
                            color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1)
                            TextInput {
                                id: newSessionExec
                                anchors.fill: parent; anchors.margins: 10
                                color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                                clip: true
                                Text { text: "EXEC COMMAND"; visible: !parent.text; color: "gray"; font.pixelSize: 10; anchors.centerIn: parent }
                            }
                        }
                        BaseButton {
                            width: 80; height: 36
                            readonly property bool canAdd: newSessionName.text.trim() !== "" && newSessionExec.text.trim() !== ""
                            enabled: canAdd
                            onClicked: {
                                SessionManager.addSession(newSessionName.text.trim(), newSessionExec.text.trim())
                                newSessionName.text = ""; newSessionExec.text = ""
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 18
                                color: parent.canAdd ? ColorManager.accentColor : Qt.rgba(1, 1, 1, 0.1)
                                opacity: parent.canAdd ? 1.0 : 0.5
                                
                                Text { 
                                    anchors.centerIn: parent; text: "ADD"
                                    font.pixelSize: 10; font.weight: Font.Bold
                                    color: parent.parent.canAdd ? "black" : "white"
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    Repeater {
                        model: SessionManager.model
                        delegate: RowLayout {
                            spacing: 10
                            BaseButton {
                                width: 400; height: 44
                                onClicked: {
                                    SessionManager.selectSession(index)
                                    mainContentRect.showSessionPicker = false
                                }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 22
                                    color: SessionManager.currentSessionName === name ? Qt.rgba(ColorManager.accentColor.r, ColorManager.accentColor.g, ColorManager.accentColor.b, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                                    border.color: SessionManager.currentSessionName === name ? ColorManager.accentColor : "transparent"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: name.toUpperCase() + "  (" + exec + ")"
                                        color: ThemeManager.contentOnBackgroundColor
                                        font.pixelSize: 11; font.letterSpacing: 1; opacity: 0.8
                                    }
                                }
                            }
                            
                            BaseButton {
                                width: 44; height: 44
                                onClicked: SessionManager.deleteSession(index)
                                
                                Rectangle {
                                    anchors.fill: parent; radius: 22
                                    color: Qt.rgba(1, 0, 0, 0.1); border.color: Qt.rgba(1, 0, 0, 0.2)
                                    Text { anchors.centerIn: parent; text: "󰆴"; color: "#ff5555"; font.pixelSize: 16 }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    BaseButton {
                        width: 180; height: 36
                        onClicked: SessionManager.resetToDefaults()
                        Rectangle {
                            anchors.fill: parent; radius: 18; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.2)
                            Text { anchors.centerIn: parent; text: "RESET TO DEFAULTS"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }
                    BaseButton {
                        width: 100; height: 36
                        onClicked: mainContentRect.showSessionPicker = false
                        Rectangle {
                            anchors.fill: parent; radius: 18; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.2)
                            Text { anchors.centerIn: parent; text: "CLOSE"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }
                }
            }
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 30
            spacing: 40
            opacity: 0.4
            
            BaseButton {
                id: pwrBtn
                onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                Text {
                    text: "󰐥  POWER OFF"
                    color: "white"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1
                    opacity: pwrBtn.isHovered ? 1.0 : 0.6
                }
            }

            BaseButton {
                id: rebBtn
                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                Text {
                    text: "󰜉  REBOOT"
                    color: "white"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1
                    opacity: rebBtn.isHovered ? 1.0 : 0.6
                }
            }

            BaseButton {
                id: ttyBtn
                onClicked: Quickshell.execDetached(["chvt", "2"])
                Text {
                    text: "󰈆  EXIT TO TTY"
                    color: "white"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1
                    opacity: ttyBtn.isHovered ? 1.0 : 0.6
                }
            }
        }
    }
}
