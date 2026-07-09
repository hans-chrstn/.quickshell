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
        anchors.margins: 12
        spacing: 16
        
        RowLayout {
            spacing: 12
            StyledLabel { text: "Select App:"; type: "body" }
            
            Repeater {
                model: appList
                BaseButton {
                    height: 30
                    Layout.preferredWidth: 80
                    cornerRadius: 8
                    
                    Rectangle { 
                        anchors.fill: parent
                        color: selectedAppIndex === index ? ThemeManager.accentColor : ThemeManager.surfaceStrongColor
                        radius: 8
                    }
                    StyledLabel {
                        anchors.centerIn: parent
                        text: modelData
                        color: selectedAppIndex === index ? "black" : "white"
                        font.pixelSize: 12
                    }
                    onClicked: selectedAppIndex = index
                }
            }
        }
        
        RowLayout {
            spacing: 12
            StyledLabel { text: "App Label:"; type: "body" }
            TextField {
                id: appNameField
                Layout.preferredWidth: 120
                color: ThemeManager.contentOnBackgroundColor
            }
            StyledLabel { text: "App Icon:"; type: "body" }
            TextField {
                id: appIconField
                Layout.preferredWidth: 60
                color: ThemeManager.contentOnBackgroundColor
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: ThemeManager.outlinePrimaryColor
        }
        
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: actionModel.count * 58
            interactive: false
            spacing: 8
            
            model: ListModel { id: actionModel }
            
            delegate: Rectangle {
                width: listView.width
                height: 50
                color: ThemeManager.surfaceStrongColor
                radius: 8
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    TextField {
                        text: model.icon || ""
                        Layout.preferredWidth: 50
                        placeholderText: "Icon"
                        color: ThemeManager.contentOnBackgroundColor
                        onTextEdited: actionModel.setProperty(index, "icon", text)
                    }
                    TextField {
                        text: model.name || ""
                        Layout.preferredWidth: 120
                        placeholderText: "Action Name"
                        color: ThemeManager.contentOnBackgroundColor
                        onTextEdited: actionModel.setProperty(index, "name", text)
                    }
                    TextField {
                        text: model.command || (model.internal ? "internal:" + model.internal : "")
                        Layout.fillWidth: true
                        placeholderText: "Shell Command"
                        color: ThemeManager.contentOnBackgroundColor
                        onTextEdited: {
                            if (text.startsWith("internal:")) {
                                actionModel.setProperty(index, "internal", text.replace("internal:", ""));
                                actionModel.setProperty(index, "command", "");
                            } else {
                                actionModel.setProperty(index, "command", text);
                                actionModel.setProperty(index, "internal", "");
                            }
                        }
                    }
                    BaseButton {
                        width: 30
                        height: 30
                        cornerRadius: 15
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: ThemeManager.red || "#FF5555"
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
                Layout.preferredWidth: 120
                height: 40
                cornerRadius: 8
                
                Rectangle { anchors.fill: parent; color: ThemeManager.surfaceStrongColor; radius: 8 }
                StyledLabel { anchors.centerIn: parent; text: "󰐕 Add Action"; color: ThemeManager.accentColor }
                
                onClicked: {
                    actionModel.append({ "name": "New Action", "icon": "󰏚", "command": "echo hello", "internal": "" })
                }
            }
            
            Item { Layout.fillWidth: true }
            
            BaseButton {
                Layout.preferredWidth: 100
                height: 40
                cornerRadius: 8
                
                Rectangle { anchors.fill: parent; color: ThemeManager.accentColor; radius: 8 }
                StyledLabel { anchors.centerIn: parent; text: "Save"; color: "black"; font.bold: true }
                
                onClicked: saveConfig()
            }
        }
    }
}
