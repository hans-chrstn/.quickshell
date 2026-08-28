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
    height: (appData === null) ? 200 : contentCol.height + 40
    
    property var configurationItemData: null
    property var appData: null
    
    function getActiveAppName(categoryData) {
        let defaultDesktop = categoryData.default
        if (!defaultDesktop) return "Not Set"
        let list = categoryData.apps
        for (let i = 0; i < list.length; i++) {
            if (list[i].desktop === defaultDesktop) {
                return list[i].name
            }
        }
        return defaultDesktop.replace(".desktop", "")
    }
    
    function getActiveAppIcon(categoryData) {
        let defaultDesktop = categoryData.default
        if (!defaultDesktop) return ""
        let list = categoryData.apps
        for (let i = 0; i < list.length; i++) {
            if (list[i].desktop === defaultDesktop) {
                return list[i].icon
            }
        }
        return ""
    }
    
    function getAppIconSource(iconName) {
        if (!iconName) return ""
        let iconStr = iconName.toString()
        if (iconStr.startsWith("/")) {
            return "file://" + iconStr
        }
        return Quickshell.iconPath(iconStr)
    }
    
    // Instant file-based cache loader
    FileView {
        id: cacheFile
        path: Quickshell.cachePath("default_apps_cache.json")
        blockLoading: false
        onLoaded: {
            if (text()) {
                try {
                    let parsed = JSON.parse(text())
                    if (Array.isArray(parsed)) {
                        appData = parsed
                    }
                } catch (e) {
                    console.log("Error parsing cached default apps: " + e)
                }
            }
        }
    }
    
    // Background scanner process
    Process {
        id: queryAppsProc
        running: true
        command: ["bash", "/home/jin/.config/quickshell/core/helpers/get_default_apps.sh"]
        stdout: StdioCollector { id: stdoutCollector }
        onExited: {
            if (stdoutCollector.text) {
                try {
                    let parsed = JSON.parse(stdoutCollector.text)
                    appData = parsed
                    // Save to cache instantly for next launch
                    cacheFile.setText(stdoutCollector.text)
                } catch (e) {
                    console.log("Error parsing default apps output: " + e)
                }
            }
        }
    }
    
    Process {
        id: setAppProc
        running: false
        onExited: {
            // Re-run the background query to update the UI & cache
            queryAppsProc.running = true
        }
    }
    
    function setDefaultApp(mimesString, desktopFile) {
        let mimes = mimesString.split(" ");
        let shCmd = "";
        for (let i = 0; i < mimes.length; i++) {
            shCmd += `xdg-mime default "${desktopFile}" "${mimes[i]}" 2>/dev/null; `;
            shCmd += `mkdir -p ~/.config; touch ~/.config/mimeapps.list; `;
            shCmd += `sed -i '/^\\[Default Applications\\]/,/^\\[/ { /^[[:space:]]*${mimes[i].replace("/", "\\/")}=/d }' ~/.config/mimeapps.list; `;
            shCmd += `sed -i '/^\\[Default Applications\\]/a ${mimes[i]}=${desktopFile}' ~/.config/mimeapps.list; `;
        }
        
        setAppProc.command = ["bash", "-c", shCmd];
        setAppProc.running = true;
    }
    
    function openAppSelector(mimesString, appsList, targetItem) {
        appSelectorMenu.activeCategory = mimesString
        appSelectorMenu.activeAppsList = appsList
        appSelectorMenu.popup()
    }
    
    // Loading State Visual (Only shown when there's no cache on first launch)
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: appData === null
        
        Rectangle {
            width: 32; height: 32; radius: 16
            color: "transparent"
            border.color: ThemeManager.accentColor
            border.width: 2
            Layout.alignment: Qt.AlignHCenter
            
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
            }
        }
        
        StyledLabel {
            text: "Scanning system associations..."
            type: "caption"
            opacity: 0.6
            Layout.alignment: Qt.AlignHCenter
        }
    }
    
    // Main Content Column (Visible instantly if cache is loaded)
    ColumnLayout {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 20
        visible: appData !== null
        
        StyledLabel {
            text: "Preferred Applications"
            type: "body"
            font.weight: Font.Bold
            opacity: 0.8
        }
        
        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 16
            columnSpacing: 16
            
            Repeater {
                model: appData
                
                Rectangle {
                    id: card
                    Layout.fillWidth: true
                    height: 94
                    color: ThemeManager.surfacePrimaryColor
                    border.color: cardHover.hovered ? ThemeManager.outlineStrongColor : ThemeManager.outlinePrimaryColor
                    border.width: 1
                    radius: 14
                    
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    scale: cardHover.hovered ? 1.01 : 1.0
                    
                    HoverHandler {
                        id: cardHover
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledLabel {
                                text: modelData.icon || "󰏚"
                                font.pixelSize: 14
                                opacity: 0.7
                            }
                            
                            StyledLabel {
                                text: modelData.label
                                font.weight: Font.Bold
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                        }
                        
                        // Selector button
                        BaseButton {
                            id: selectorBtn
                            height: 38
                            Layout.fillWidth: true
                            cornerRadius: 8
                            
                            Rectangle {
                                anchors.fill: parent
                                color: parent.isHovered ? ThemeManager.surfaceVariantColor : ThemeManager.surfaceVariantStrongColor
                                border.color: ThemeManager.outlinePrimaryColor
                                border.width: 1
                                radius: 8
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10
                                
                                Item {
                                    width: 22; height: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    
                                    Image {
                                        id: appIconImg
                                        anchors.fill: parent
                                        source: getAppIconSource(getActiveAppIcon(modelData))
                                        fillMode: Image.PreserveAspectFit
                                        visible: source.toString() !== ""
                                    }
                                    
                                    StyledLabel {
                                        anchors.centerIn: parent
                                        text: "󰏚"
                                        font.pixelSize: 12
                                        visible: appIconImg.status !== Image.Ready
                                    }
                                }
                                
                                StyledLabel {
                                    text: getActiveAppName(modelData)
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                StyledLabel {
                                    text: "󰅀"
                                    font.pixelSize: 10
                                    opacity: 0.5
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                            
                            onClicked: {
                                openAppSelector(modelData.mimes, modelData.apps, selectorBtn)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Popup App Selector Menu
    BaseContextMenu {
        id: appSelectorMenu
        width: 240
        
        property string activeCategory: ""
        property var activeAppsList: []
        
        Repeater {
            model: appSelectorMenu.activeAppsList
            delegate: MenuItem {
                id: menuItem
                visible: true
                height: 38
                
                background: Rectangle {
                    color: menuItem.hovered ? ThemeManager.surfaceVariantColor : "transparent"
                    radius: 8
                }
                
                contentItem: RowLayout {
                    spacing: 10
                    anchors.fill: parent
                    anchors.margins: 6
                    
                    Item {
                        width: 22; height: 22
                        Layout.alignment: Qt.AlignVCenter
                        
                        Image {
                            id: itemIconImg
                            anchors.fill: parent
                            source: getAppIconSource(modelData.icon)
                            fillMode: Image.PreserveAspectFit
                            visible: source.toString() !== ""
                        }
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "󰏚"
                            font.pixelSize: 11
                            visible: itemIconImg.status !== Image.Ready
                        }
                    }
                    
                    StyledLabel {
                        text: modelData.name || ""
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
                
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                
                onTriggered: {
                    setDefaultApp(appSelectorMenu.activeCategory, modelData.desktop)
                    appSelectorMenu.close()
                }
            }
        }
    }
}
