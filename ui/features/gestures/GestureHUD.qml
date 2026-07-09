import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import QtQuick.Window

PanelWindow {
    id: hudWindow
    
    anchors {
        left: true; right: true; top: true; bottom: true
    }
    
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    property bool isVisible: GestureManager.isGestureActive
    
    visible: isVisible
    
    property real centerX: width / 2
    property real centerY: height / 2
    property real currentX: width / 2
    property real currentY: height / 2
    property bool readyToDraw: false
    
    property string activeApp: ""
    property string initOutput: ""
    
    property var gesturesData: ({})
    property var availablePages: []
    property int currentPageIndex: 0
    
    function refreshPages() {
        let keys = ["global"];
        if (activeApp && activeApp !== "" && activeApp !== "global") {
            keys.push(activeApp);
        }
        availablePages = keys;
        
        let targetIndex = keys.indexOf(activeApp);
        if (targetIndex !== -1) {
            currentPageIndex = targetIndex;
        } else {
            currentPageIndex = keys.indexOf("global") !== -1 ? keys.indexOf("global") : 0;
        }
        activeConfig = getActiveConfig();
    }
    
    function formatPageName(pageKey) {
        if (!pageKey) return "";
        let pageObj = gesturesData[pageKey];
        if (pageObj) {
            let iconStr = pageObj.icon ? (pageObj.icon + "\n") : "";
            let nameStr = pageObj.name ? pageObj.name : (pageKey.charAt(0).toUpperCase() + pageKey.slice(1));
            return iconStr + nameStr;
        }
        return pageKey.charAt(0).toUpperCase() + pageKey.slice(1);
    }
    
    onActiveAppChanged: refreshPages()
    
    FileView {
        id: gesturesConfigFile
        path: Quickshell.cachePath("gestures.json")
        blockLoading: true
        watchChanges: true
        
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
                setText(JSON.stringify(defaultData, null, 4));
                hudWindow.gesturesData = defaultData;
                hudWindow.refreshPages();
                hudWindow.activeConfig = hudWindow.getActiveConfig();
                return;
            }
            try {
                let parsed = JSON.parse(text())
                hudWindow.gesturesData = parsed
                hudWindow.refreshPages()
                hudWindow.activeConfig = hudWindow.getActiveConfig()
            } catch (e) {
                console.log("Error parsing gestures.json: " + e)
            }
        }
        
        onInternalTextChanged: parseGesturesData()
        onLoaded: parseGesturesData()
        Component.onCompleted: parseGesturesData()
    }
    
    function getActiveConfig() {
        let pageName = availablePages[currentPageIndex];
        if (!pageName) return [];
        
        let pageObj = gesturesData[pageName];
        let baseConf = (pageObj && pageObj.actions) ? pageObj.actions : [];
        
        let configWithAdd = []
        for (let i = 0; i < baseConf.length; i++) {
            configWithAdd.push(baseConf[i])
        }
        
        if (pageName !== "global") {
            configWithAdd.push({
                name: pageObj ? "Edit App" : "Add App",
                icon: "󰏚",
                internal: "edit_config",
                targetApp: pageName
            })
        }
        
        return configWithAdd
    }
    
    property var activeConfig: getActiveConfig()
    onCurrentPageIndexChanged: activeConfig = getActiveConfig()
    property int selectedIndex: -1
    
    onIsVisibleChanged: {
        if (isVisible) {
            ViewManager.closeAllWindows();
            
            gesturesConfigFile.reload();
            
            let activeTop = WindowManager.focusedWindow;
            let isActivated = true;
            if (activeTop && activeTop.hasOwnProperty("activated")) {
                isActivated = activeTop.activated;
            }
            hudWindow.activeApp = (activeTop && isActivated) ? activeTop.appId.toLowerCase() : "";
            refreshPages();
            
            readyToDraw = false;
            initProc.running = true;
        } else {
            selectedIndex = -1;
            readyToDraw = false;
        }
    }
    
    Connections {
        target: GestureManager
        function onGestureDeltaXChanged() {
            if (readyToDraw) {
                hudWindow.currentX = hudWindow.centerX + GestureManager.gestureDeltaX;
            }
        }
        function onGestureDeltaYChanged() {
            if (readyToDraw) {
                hudWindow.currentY = hudWindow.centerY + GestureManager.gestureDeltaY;
            }
        }
    }
    
    onCurrentXChanged: updateSelection()
    onCurrentYChanged: updateSelection()
    
    Process {
        id: execProc
        stdout: SplitParser {
            onRead: (data) => console.log("execProc stdout: " + data)
        }
        stderr: SplitParser {
            onRead: (data) => console.log("execProc stderr: " + data)
        }
    }
    
    Process {
        id: initProc
        command: ["sh", "-c", "hyprctl cursorpos; echo '==='; hyprctl monitors -j"]
        stdout: SplitParser {
            onRead: (data) => {
                hudWindow.initOutput += data + "\n";
            }
        }
        onExited: (code) => {
            if (code === 0) {
                try {
                    let parts = hudWindow.initOutput.split("===\n");
                    
                    if (parts.length >= 2) {
                        let curStr = parts[0].trim().split(",");
                        let globalX = parseInt(curStr[0].trim());
                        let globalY = parseInt(curStr[1].trim());
                        
                        let monsData = JSON.parse(parts[1]);
                        let activeMon = monsData.find(m => m.focused);
                        if (activeMon) {
                            globalX -= activeMon.x;
                            globalY -= activeMon.y;
                            ViewManager.trackScreen(activeMon.name);
                        }
                        
                        let padding = 150; 
                        if (globalX < padding) globalX = padding;
                        if (globalX > hudWindow.width - padding) globalX = hudWindow.width - padding;
                        if (globalY < padding) globalY = padding;
                        if (globalY > hudWindow.height - padding) globalY = hudWindow.height - padding;
                        
                        hudWindow.centerX = globalX;
                        hudWindow.centerY = globalY;
                        hudWindow.currentX = hudWindow.centerX;
                        hudWindow.currentY = hudWindow.centerY;
                        
                        hudWindow.readyToDraw = true;
                        updateSelection();
                    }
                } catch (e) {
                    console.log("initProc error: " + e);
                }
            }
            hudWindow.initOutput = "";
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onPositionChanged: (mouse) => {
            if (!readyToDraw) return;
            hudWindow.currentX = mouse.x;
            hudWindow.currentY = mouse.y;
        }
        
        onWheel: (wheel) => {
            if (!readyToDraw || availablePages.length === 0) return;
            if (wheel.angleDelta.y > 0) {
                currentPageIndex = (currentPageIndex + 1) % availablePages.length;
            } else if (wheel.angleDelta.y < 0) {
                currentPageIndex = (currentPageIndex - 1 + availablePages.length) % availablePages.length;
            }
        }
        
        onClicked: (mouse) => {
            if (selectedIndex >= 0 && selectedIndex < activeConfig.length && readyToDraw) {
                let item = activeConfig[selectedIndex];
                if (item.internal) {
                    if (item.internal === "close_window") {
                        if (ToplevelManager.activeToplevel) ToplevelManager.activeToplevel.close();
                    } else if (item.internal === "maximize_window") {
                        if (ToplevelManager.activeToplevel) ToplevelManager.activeToplevel.maximized = !ToplevelManager.activeToplevel.maximized;
                    } else if (item.internal === "fullscreen_window") {
                        if (ToplevelManager.activeToplevel) ToplevelManager.activeToplevel.fullscreen = !ToplevelManager.activeToplevel.fullscreen;
                    } else if (item.internal === "edit_config") {
                        let targetApp = item.targetApp || activeApp;
                        if (!hudWindow.gesturesData[targetApp]) {
                            let newData = Object.assign({}, hudWindow.gesturesData);
                            newData[targetApp] = { name: targetApp, icon: "󰏚", actions: [] };
                            
                            gesturesConfigFile.setText(JSON.stringify(newData, null, 4));
                        }
                        ViewManager.openWindow("settings");
                    } else if (item.internal === "open_launcher") {
                        ViewManager.toggleWindow("commandPalette");
                    } else if (item.internal === "open_settings") {
                        ViewManager.openWindow("settings");
                    }
                } else if (item.command) {
                    Quickshell.execDetached(["sh", "-c", item.command]);
                }
            }
            GestureManager.isGestureActive = false;
        }
    }
    
    function updateSelection() {
        if (!readyToDraw) return;
        
        let n = activeConfig.length;
        if (n === 0) return;
        
        let bestIndex = -1;
        
        for (let i = 0; i < n; i++) {
            let angle = (i * (360 / n)) - 90;
            let rad = angle * Math.PI / 180;
            let btnX = centerX + Math.cos(rad) * 100;
            let btnY = centerY + Math.sin(rad) * 100;
            
            let dx = currentX - btnX;
            let dy = currentY - btnY;
            let dist = Math.sqrt(dx*dx + dy*dy);
            
            if (dist < 45) {
                bestIndex = i;
                break;
            }
        }
        
        selectedIndex = bestIndex;
    }
    Component {
        id: styleDefault
        Item {
            id: styleRootDefault
            anchors.fill: parent
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)
                opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            Item {
                id: menuContainerDefault
                x: hudWindow.centerX - width/2
                y: hudWindow.centerY - height/2
                width: 300
                height: 300
                opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Rectangle {
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    radius: 30
                    color: ThemeManager.backgroundColor
                    border.width: 2
                    border.color: ThemeManager.accentColor
                    Text {
                        anchors.centerIn: parent
                        text: hudWindow.formatPageName(hudWindow.availablePages[hudWindow.currentPageIndex])
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 10
                        wrapMode: Text.Wrap
                    }
                }
                Rectangle {
                    x: parent.width/2
                    y: parent.height/2
                    width: Math.sqrt(Math.pow(hudWindow.currentX - hudWindow.centerX, 2) + Math.pow(hudWindow.currentY - hudWindow.centerY, 2))
                    height: 2
                    color: ThemeManager.accentColor
                    opacity: 0.5
                    transformOrigin: Item.TopLeft
                    rotation: Math.atan2(hudWindow.currentY - hudWindow.centerY, hudWindow.currentX - hudWindow.centerX) * 180 / Math.PI
                    visible: width > 20
                }
                Repeater {
                    model: hudWindow.activeConfig
                    Item {
                        width: 60
                        height: 60
                        property real angle: (index * (360 / hudWindow.activeConfig.length)) - 90
                        property real rad: angle * Math.PI / 180
                        property real dist: 100
                        x: menuContainerDefault.width/2 + Math.cos(rad) * dist - width/2
                        y: menuContainerDefault.height/2 + Math.sin(rad) * dist - height/2
                        property bool isSelected: index === hudWindow.selectedIndex
                        Rectangle {
                            anchors.fill: parent
                            radius: 30
                            color: isSelected ? ThemeManager.accentColor : "black"
                            opacity: isSelected ? 0.9 : 0.7
                            border.width: 2
                            border.color: isSelected ? "white" : ThemeManager.outlinePrimaryColor
                            scale: isSelected ? 1.1 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.pixelSize: 24
                                color: isSelected ? "black" : "white"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name
                                font.pixelSize: 10
                                font.bold: true
                                color: isSelected ? "black" : "white"
                                visible: isSelected
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: styleCtos
        Item {
            id: styleRootCtos
            anchors.fill: parent
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.02, 0.05, 0.08, 0.8)
                opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Repeater {
                    model: Math.ceil(parent.height / 4)
                    Rectangle {
                        y: index * 4
                        width: parent.width
                        height: 1
                        color: ThemeManager.accentColor
                        opacity: 0.03
                    }
                }
            }
            Item {
                id: menuContainerCtos
                x: hudWindow.centerX - width/2
                y: hudWindow.centerY - height/2
                width: 300
                height: 300
                opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Rectangle {
                    x: parent.width/2
                    y: parent.height/2
                    width: Math.sqrt(Math.pow(hudWindow.currentX - hudWindow.centerX, 2) + Math.pow(hudWindow.currentY - hudWindow.centerY, 2))
                    height: 1
                    color: ThemeManager.accentColor
                    transformOrigin: Item.TopLeft
                    rotation: Math.atan2(hudWindow.currentY - hudWindow.centerY, hudWindow.currentX - hudWindow.centerX) * 180 / Math.PI
                    visible: width > 30
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 6
                        color: ThemeManager.accentColor
                        opacity: 0.2
                    }
                }
                Item {
                    anchors.centerIn: parent
                    width: 80
                    height: 80
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: ThemeManager.accentColor
                        opacity: 0.4
                        radius: width/2
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: ThemeManager.accentColor
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: ThemeManager.accentColor
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        NumberAnimation on rotation {
                            from: 0; to: 360
                            duration: 6000
                            loops: Animation.Infinite
                            running: hudWindow.isVisible
                        }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 60
                        height: 60
                        radius: 30
                        color: Qt.rgba(0.02, 0.05, 0.08, 0.9)
                        border.width: 1
                        border.color: ThemeManager.accentColor
                        Text {
                            anchors.centerIn: parent
                            text: "[ " + hudWindow.formatPageName(hudWindow.availablePages[hudWindow.currentPageIndex]) + " ]"
                            color: ThemeManager.accentColor
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "monospace"
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width - 6
                            wrapMode: Text.Wrap
                        }
                    }
                }
                Repeater {
                    model: hudWindow.activeConfig
                    Item {
                        width: 64
                        height: 64
                        property real angle: (index * (360 / hudWindow.activeConfig.length)) - 90
                        property real rad: angle * Math.PI / 180
                        property real dist: 100
                        x: menuContainerCtos.width/2 + Math.cos(rad) * dist - width/2
                        y: menuContainerCtos.height/2 + Math.sin(rad) * dist - height/2
                        property bool isSelected: index === hudWindow.selectedIndex
                        Rectangle {
                            anchors.fill: parent
                            radius: 32
                            color: isSelected ? ThemeManager.accentColor : Qt.rgba(0.02, 0.05, 0.08, 0.9)
                            opacity: isSelected ? 1.0 : 0.8
                            border.width: isSelected ? 2 : 1
                            border.color: ThemeManager.accentColor
                            scale: isSelected ? 1.1 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 12
                                height: parent.height + 12
                                radius: width/2
                                color: "transparent"
                                border.width: 1
                                border.color: ThemeManager.accentColor
                                opacity: isSelected ? 0.5 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                NumberAnimation on rotation {
                                    from: 360; to: 0
                                    duration: 3000
                                    loops: Animation.Infinite
                                    running: hudWindow.isVisible && isSelected
                                }
                                Rectangle {
                                    width: 8; height: 2; color: ThemeManager.accentColor
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 8; height: 2; color: ThemeManager.accentColor
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.pixelSize: 22
                                color: isSelected ? "black" : ThemeManager.accentColor
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name.toUpperCase()
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "monospace"
                                color: isSelected ? "black" : ThemeManager.accentColor
                                visible: isSelected
                            }
                        }
                    }
                }
            }
        }
    }


    Loader {
        anchors.fill: parent
        sourceComponent: {
            if (ThemeManager.radialMenuStyle === "ctos") return styleCtos;
            return styleDefault;
        }
    }
}
