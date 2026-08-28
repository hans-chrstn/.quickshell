import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared

Item {
    id: root
    width: parent ? parent.width : 0
    height: contentCol.height + 40
    
    property var configurationItemData: null
    property var gesturesData: ({})
    property var appList: []
    property int selectedAppIndex: 0
    property string activeApp: appList.length > 0 ? appList[selectedAppIndex] : ""
    
    onActiveAppChanged: {
        loadActionsForApp()
    }
    
    property bool isLoaded: false
    
    FileView {
        id: gesturesConfigFile
        path: Quickshell.cachePath("gestures.json")
        blockLoading: true
        
        function parseGesturesData() {
            if (!text()) {
                let defaultData = {
                    "global": {
                        "name": "Global",
                        "icon": "󰇄",
                        "actions": [
                            { "name": "Terminal", "icon": "󰆍", "command": "kitty" },
                            { "name": "Browser", "icon": "󰈹", "command": "zen-beta" },
                            { "name": "Files", "icon": "󰉋", "command": "kitty -e yazi" },
                            { "name": "Settings", "icon": "󰒓", "internal": "open_settings" },
                            { "name": "Launcher", "icon": "󱓞", "internal": "open_launcher" }
                        ]
                    }
                };
                gesturesData = defaultData;
                let keys = Object.keys(gesturesData);
                appList = keys;
                selectedAppIndex = 0;
                loadActionsForApp();
                root.isLoaded = true;
                return;
            }
            try {
                let parsed = JSON.parse(text())
                gesturesData = parsed;
                
                let keys = Object.keys(parsed);
                if (keys.indexOf("global") === -1) keys.push("global");
                appList = keys;
                
                if (selectedAppIndex >= appList.length) selectedAppIndex = 0;
                loadActionsForApp();
                root.isLoaded = true;
            } catch (e) {
                console.log("Error parsing gestures.json in editor: " + e)
            }
        }
        
        onInternalTextChanged: {
            parseGesturesData()
        }
        onLoaded: parseGesturesData()
        Component.onCompleted: parseGesturesData()
    }
    
    function loadActionsForApp() {
        actionModel.clear();
        if (!activeApp) return;
        
        let appObj = gesturesData[activeApp];
        if (appObj) {
            appNameField.text = appObj.name || activeApp;
            appIconField.text = appObj.icon || "󰏚";
            if (appObj.actions) {
                for (let i = 0; i < appObj.actions.length; i++) {
                    let act = appObj.actions[i];
                    actionModel.append({
                        name: act.name || "",
                        icon: act.icon || "",
                        command: act.command || "",
                        internal: act.internal || ""
                    });
                }
            }
        } else {
            appNameField.text = activeApp;
            appIconField.text = "󰏚";
        }
    }
    
    function saveConfig() {
        let configPath = Quickshell.cachePath("gestures.json");
        let newActions = [];
        for (let i = 0; i < actionModel.count; i++) {
            let act = actionModel.get(i);
            let a = { name: act.name, icon: act.icon };
            if (act.internal) a.internal = act.internal;
            if (act.command) a.command = act.command;
            newActions.push(a);
        }
        
        if (!gesturesData[activeApp]) gesturesData[activeApp] = {};
        gesturesData[activeApp].actions = newActions;
        gesturesData[activeApp].name = appNameField.text;
        gesturesData[activeApp].icon = appIconField.text;
        
        gesturesConfigFile.setText(JSON.stringify(gesturesData, null, 4));
    }
    
    Component.onCompleted: {
        if (gesturesConfigFile.text()) {
            gesturesConfigFile.parseGesturesData();
        }
    }
    
    ColumnLayout {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 20
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            
            // App settings Column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                
                RowLayout {
                    spacing: 12
                    StyledLabel { text: "Select App:"; type: "body"; font.weight: Font.Bold }
                    
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: appList
                            BaseButton {
                                height: 30
                                Layout.preferredWidth: 90
                                cornerRadius: 15
                                
                                Rectangle { 
                                    anchors.fill: parent
                                    color: selectedAppIndex === index ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
                                    border.color: selectedAppIndex === index ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                                    border.width: 1
                                    radius: 15
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: (modelData === "global" ? "󰇄 " : "󰏚 ") + modelData.toUpperCase()
                                    color: selectedAppIndex === index ? "black" : ThemeManager.secondaryTextColor
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                onClicked: selectedAppIndex = index
                            }
                        }
                    }
                }
                
                RowLayout {
                    spacing: 16
                    
                    ColumnLayout {
                        spacing: 6
                        StyledLabel { text: "App Label"; type: "caption"; opacity: 0.6 }
                        TextField {
                            id: appNameField
                            Layout.preferredWidth: 160
                            height: 36
                            color: ThemeManager.contentOnBackgroundColor
                            selectByMouse: true
                            font.family: ThemeManager.fontFamily
                            font.pixelSize: 12
                            padding: 8
                            background: Rectangle {
                                color: parent.activeFocus ? ThemeManager.surfaceVariantColor : ThemeManager.surfacePrimaryColor
                                border.color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                                border.width: 1
                                radius: 8
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        spacing: 6
                        StyledLabel { text: "App Icon"; type: "caption"; opacity: 0.6 }
                        TextField {
                            id: appIconField
                            Layout.preferredWidth: 80
                            height: 36
                            color: ThemeManager.contentOnBackgroundColor
                            selectByMouse: true
                            font.family: ThemeManager.fontFamily
                            font.pixelSize: 12
                            padding: 8
                            horizontalAlignment: TextInput.AlignHCenter
                            background: Rectangle {
                                color: parent.activeFocus ? ThemeManager.surfaceVariantColor : ThemeManager.surfacePrimaryColor
                                border.color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                                border.width: 1
                                radius: 8
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }
            }
            
            // Dynamic Radial Preview Dial
            Rectangle {
                width: 120; height: 120; radius: 60
                color: "transparent"
                border.color: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.12)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter
                
                // Center glow dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 8; height: 8; radius: 4
                    color: ThemeManager.accentColor
                    opacity: 0.25
                }
                
                Repeater {
                    model: actionModel
                    Item {
                        width: 0; height: 0
                        x: 60; y: 60 // Center
                        
                        readonly property real angle: actionModel.count > 0 ? (index * 360 / actionModel.count) - 90 : -90
                        readonly property real rad: angle * Math.PI / 180
                        readonly property real radiusDistance: 40
                        
                        Item {
                            x: Math.cos(rad) * radiusDistance - width/2
                            y: Math.sin(rad) * radiusDistance - height/2
                            width: 24; height: 24
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: ThemeManager.surfaceStrongColor
                                border.color: ThemeManager.accentColor
                                border.width: 0.5
                            }
                            
                            StyledLabel {
                                anchors.centerIn: parent
                                text: model.icon || "󰏚"
                                font.pixelSize: 11
                            }
                            
                            StyledLabel {
                                anchors.top: parent.bottom
                                anchors.topMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.name || ""
                                font.pixelSize: 7
                                font.weight: Font.Bold
                                opacity: 0.6
                            }
                        }
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: ThemeManager.outlinePrimaryColor
            opacity: 0.5
        }
        
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: actionModel.count * 64
            interactive: false
            spacing: 8
            
            model: ListModel { id: actionModel }
            
            delegate: Rectangle {
                id: itemCard
                width: listView.width
                height: 56
                color: ThemeManager.surfacePrimaryColor
                border.color: hoveredHandler.hovered ? ThemeManager.outlineStrongColor : ThemeManager.outlinePrimaryColor
                border.width: 1
                radius: 12
                
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                scale: hoveredHandler.hovered ? 1.01 : 1.0
                
                HoverHandler {
                    id: hoveredHandler
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12
                    
                    TextField {
                        text: model.icon || ""
                        Layout.preferredWidth: 50
                        Layout.fillHeight: true
                        placeholderText: "Icon"
                        color: ThemeManager.contentOnBackgroundColor
                        font.family: ThemeManager.fontFamily
                        horizontalAlignment: TextInput.AlignHCenter
                        selectByMouse: true
                        onTextEdited: actionModel.setProperty(index, "icon", text)
                        background: Rectangle {
                            color: parent.activeFocus ? ThemeManager.surfaceVariantColor : ThemeManager.surfaceStrongColor
                            border.color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                            border.width: 1
                            radius: 8
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    TextField {
                        text: model.name || ""
                        Layout.preferredWidth: 140
                        Layout.fillHeight: true
                        placeholderText: "Action Name"
                        color: ThemeManager.contentOnBackgroundColor
                        font.family: ThemeManager.fontFamily
                        selectByMouse: true
                        onTextEdited: actionModel.setProperty(index, "name", text)
                        background: Rectangle {
                            color: parent.activeFocus ? ThemeManager.surfaceVariantColor : ThemeManager.surfaceStrongColor
                            border.color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                            border.width: 1
                            radius: 8
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    TextField {
                        text: model.command || (model.internal ? "internal:" + model.internal : "")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Shell Command"
                        color: ThemeManager.contentOnBackgroundColor
                        font.family: ThemeManager.fontFamily
                        selectByMouse: true
                        onTextEdited: {
                            if (text.startsWith("internal:")) {
                                actionModel.setProperty(index, "internal", text.replace("internal:", ""));
                                actionModel.setProperty(index, "command", "");
                            } else {
                                actionModel.setProperty(index, "command", text);
                                actionModel.setProperty(index, "internal", "");
                            }
                        }
                        background: Rectangle {
                            color: parent.activeFocus ? ThemeManager.surfaceVariantColor : ThemeManager.surfaceStrongColor
                            border.color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                            border.width: 1
                            radius: 8
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    BaseButton {
                        width: 32
                        height: 32
                        cornerRadius: 16
                        
                        Rectangle {
                            anchors.fill: parent
                            color: parent.isHovered ? Qt.rgba(ThemeManager.dangerPrimaryColor.r, ThemeManager.dangerPrimaryColor.g, ThemeManager.dangerPrimaryColor.b, 0.15) : "transparent"
                            border.color: parent.isHovered ? ThemeManager.dangerPrimaryColor : "transparent"
                            border.width: 1
                            radius: 16
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: parent.isHovered ? ThemeManager.dangerPrimaryColor : ThemeManager.secondaryTextColor
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        onClicked: {
                            actionModel.remove(index)
                        }
                    }
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            BaseButton {
                Layout.preferredWidth: 130
                height: 38
                cornerRadius: 8
                
                Rectangle { 
                    anchors.fill: parent
                    color: parent.isHovered ? ThemeManager.surfaceVariantColor : ThemeManager.surfacePrimaryColor
                    border.color: ThemeManager.outlinePrimaryColor
                    border.width: 1
                    radius: 8 
                }
                StyledLabel { 
                    anchors.centerIn: parent
                    text: "󰐕 Add Action"
                    color: ThemeManager.accentColor 
                    font.weight: Font.Bold
                    font.pixelSize: 11
                }
                
                onClicked: {
                    actionModel.append({ "name": "New Action", "icon": "󰏚", "command": "echo hello", "internal": "" })
                }
            }
            
            Item { Layout.fillWidth: true }
            
            BaseButton {
                Layout.preferredWidth: 100
                height: 38
                cornerRadius: 8
                
                Rectangle { 
                    anchors.fill: parent
                    color: parent.isPressed ? Qt.darker(ThemeManager.accentColor, 1.2) : ThemeManager.accentColor
                    radius: 8 
                }
                StyledLabel { 
                    anchors.centerIn: parent
                    text: "Save"
                    color: "black"
                    font.bold: true 
                    font.pixelSize: 11
                }
                
                onClicked: saveConfig()
            }
        }
    }
}
