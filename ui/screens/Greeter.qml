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

            if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_Backspace) {
                SoundManager.playClick()
                if (event.modifiers & Qt.ControlModifier) {
                    if (!root.isUserSelected) mainContentRect.usernameBuffer = ""
                    else mainContentRect.passwordBuffer = ""
                } else {
                    if (!root.isUserSelected) {
                        if (mainContentRect.usernameBuffer.length > 0)
                            mainContentRect.usernameBuffer = mainContentRect.usernameBuffer.slice(0, -1)
                    } else {
                        if (mainContentRect.passwordBuffer.length > 0)
                            mainContentRect.passwordBuffer = mainContentRect.passwordBuffer.slice(0, -1)
                    }
                }
                event.accepted = true
                return
            }
            
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (!root.isUserSelected) {
                    if (mainContentRect.usernameBuffer.length > 0) {
                        mainContentRect.statusMessage = "Authenticating..."
                        mainContentRect.isErrorMessage = false
                        Greetd.createSession(mainContentRect.usernameBuffer)
                    }
                } else {
                    if (Greetd.state === GreetdState.Authenticating) {
                        mainContentRect.statusMessage = "Verifying..."
                        mainContentRect.isErrorMessage = false
                        Greetd.respond(mainContentRect.passwordBuffer)
                        mainContentRect.passwordBuffer = ""
                    } else if (Greetd.state === GreetdState.Inactive) {
                        mainContentRect.statusMessage = "Authenticating..."
                        mainContentRect.isErrorMessage = false
                        Greetd.createSession(Greetd.user)
                    } else if (Greetd.state === GreetdState.ReadyToLaunch) {
                        mainContentRect.statusMessage = "Launching Session..."
                        launchTimer.start()
                    }
                }
                event.accepted = true
                return
            }
            
            if (event.key === Qt.Key_Escape) {
                if (root.isUserSelected) {
                    Greetd.cancelSession()
                    Greetd.createSession("")
                    mainContentRect.passwordBuffer = ""
                    mainContentRect.usernameBuffer = ""
                    mainContentRect.statusMessage = "Enter Username"
                    mainContentRect.isErrorMessage = false
                    SoundManager.playOff()
                }
                event.accepted = true
                return
            }
            
            if (event.text.length === 1 && event.text !== "\r" && event.text !== "\n") {
                SoundManager.playClick()
                if (!root.isUserSelected) {
                    mainContentRect.usernameBuffer += event.text
                } else {
                    mainContentRect.passwordBuffer += event.text
                }
                event.accepted = true
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
                root.visible = false
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
            interval: 1000
            onTriggered: {
                root.visible = false
                let cmdString = SessionManager.currentSessionExec
                let cmd = []
                if (cmdString !== "") {
                    cmd = cmdString.match(/[^\s"']+|"([^"]*)"|'([^']*)'/g).map(arg => {
                        if (arg.startsWith('"') || arg.startsWith("'")) return arg.slice(1, -1)
                        return arg
                    })
                }
                
                Greetd.launch(cmd, ["XDG_SESSION_TYPE=wayland"])
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

                        StyledLabel {
                            id: userDisplayLabel
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isUserSelected ? Greetd.user.toUpperCase() : (mainContentRect.usernameBuffer || "TYPE USERNAME").toUpperCase()
                            type: "greeterUser"
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

                            StyledLabel {
                                id: usernameDisplayLabel
                                anchors.centerIn: parent
                                visible: !root.isUserSelected
                                text: mainContentRect.usernameBuffer
                                type: "body"
                                font.weight: Font.Medium
                                font.pixelSize: 16
                            }
                            
                            StyledLabel {
                                anchors.centerIn: parent
                                text: root.isUserSelected ? (mainContentRect.passwordBuffer.length === 0 ? "PASSWORD" : "") : ""
                                type: "caption"
                                opacity: 0.2; font.weight: Font.Black; font.letterSpacing: 1; font.pixelSize: 12
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
                        
                        StyledLabel {
                            text: root.isUserSelected ? "󰌾  ESC TO CHANGE USER" : "󰌾  ENTER TO SELECT"
                            type: "caption"
                            font.weight: Font.Bold; font.letterSpacing: 1; font.pixelSize: 8
                        }
                    }

                    BaseButton {
                        id: sessionPickerBtn
                        Layout.alignment: Qt.AlignHCenter
                        width: 320; height: 30
                        onClicked: mainContentRect.showSessionPicker = !mainContentRect.showSessionPicker
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(1, 1, 1, 0.05)
                            radius: 15
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1
                            scale: sessionPickerBtn.isHovered ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                StyledLabel {
                                    text: "󰊠  " + SessionManager.currentSessionName.toUpperCase()
                                    type: "caption"
                                    font.weight: Font.Black; font.letterSpacing: 1; font.pixelSize: 10
                                    opacity: 0.6
                                }
                                StyledLabel {
                                    text: "󱗘"
                                    type: "caption"
                                    customColor: ColorManager.accentColor
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
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: mainContentRect.statusMessage.toUpperCase()
                        type: "caption"
                        customColor: mainContentRect.isErrorMessage ? ThemeManager.dangerColor : ThemeManager.accentColor
                        font.weight: Font.Black; font.letterSpacing: 1.5; font.pixelSize: 10
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
                
                StyledLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: "SESSION MANAGEMENT"
                    type: "title"
                    customColor: ColorManager.accentColor
                    font.weight: Font.Black; font.letterSpacing: 3; font.pixelSize: 16
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
                                color: "white"; font.family: ThemeManager.fontFamily; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                                clip: true
                                StyledLabel { text: "NAME"; type: "caption"; visible: !parent.text; opacity: 0.5; font.pixelSize: 10; anchors.centerIn: parent }
                            }
                        }
                        Rectangle {
                            width: 250; height: 36; radius: 18
                            color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1)
                            TextInput {
                                id: newSessionExec
                                anchors.fill: parent; anchors.margins: 10
                                color: "white"; font.family: ThemeManager.fontFamily; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                                clip: true
                                StyledLabel { text: "EXEC COMMAND"; type: "caption"; visible: !parent.text; opacity: 0.5; font.pixelSize: 10; anchors.centerIn: parent }
                            }
                        }
                        BaseButton {
                            id: addSessionBtn
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
                                color: addSessionBtn.canAdd ? ColorManager.accentColor : Qt.rgba(1, 1, 1, 0.1)
                                opacity: addSessionBtn.canAdd ? 1.0 : 0.5
                                scale: addSessionBtn.isHovered && addSessionBtn.canAdd ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                
                                StyledLabel { 
                                    anchors.centerIn: parent; text: "ADD"
                                    type: "caption"
                                    font.weight: Font.Bold; font.pixelSize: 10
                                    customColor: addSessionBtn.canAdd ? "black" : "white"
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
                                id: sessionItemBtn
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
                                    scale: sessionItemBtn.isHovered ? 1.02 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                    
                                    StyledLabel {
                                        anchors.centerIn: parent
                                        text: name.toUpperCase() + "  (" + exec + ")"
                                        type: "body"
                                        font.pixelSize: 11; font.letterSpacing: 1; opacity: 0.8
                                    }
                                }
                            }
                            
                            BaseButton {
                                id: deleteSessionBtn
                                width: 44; height: 44
                                onClicked: SessionManager.deleteSession(index)
                                
                                Rectangle {
                                    anchors.fill: parent; radius: 22
                                    color: Qt.rgba(1, 0, 0, 0.1); border.color: Qt.rgba(1, 0, 0, 0.2)
                                    scale: deleteSessionBtn.isHovered ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                    StyledLabel { anchors.centerIn: parent; text: "󰆴"; type: "body"; customColor: "#ff5555"; font.pixelSize: 16 }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    BaseButton {
                        id: resetSessionsBtn
                        width: 180; height: 36
                        onClicked: SessionManager.resetToDefaults()
                        Rectangle {
                            anchors.fill: parent; radius: 18; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.2)
                            scale: resetSessionsBtn.isHovered ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                            StyledLabel { anchors.centerIn: parent; text: "RESET TO DEFAULTS"; type: "caption"; font.weight: Font.Bold; font.pixelSize: 10 }
                        }
                    }
                    BaseButton {
                        id: closePickerBtn
                        width: 100; height: 36
                        onClicked: mainContentRect.showSessionPicker = false
                        Rectangle {
                            anchors.fill: parent; radius: 18; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.2)
                            scale: closePickerBtn.isHovered ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                            StyledLabel { anchors.centerIn: parent; text: "CLOSE"; type: "caption"; font.weight: Font.Bold; font.pixelSize: 10 }
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
                StyledLabel {
                    text: "󰐥  POWER OFF"
                    type: "caption"
                    font.weight: Font.Bold; font.letterSpacing: 1; font.pixelSize: 9
                    opacity: pwrBtn.isHovered ? 1.0 : 0.6
                }
            }

            BaseButton {
                id: rebBtn
                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                StyledLabel {
                    text: "󰜉  REBOOT"
                    type: "caption"
                    font.weight: Font.Bold; font.letterSpacing: 1; font.pixelSize: 9
                    opacity: rebBtn.isHovered ? 1.0 : 0.6
                }
            }

            BaseButton {
                id: ttyBtn
                onClicked: Quickshell.execDetached(["chvt", "2"])
                StyledLabel {
                    text: "󰈆  EXIT TO TTY"
                    type: "caption"
                    font.weight: Font.Bold; font.letterSpacing: 1; font.pixelSize: 9
                    opacity: ttyBtn.isHovered ? 1.0 : 0.6
                }
            }
        }
    }
}
