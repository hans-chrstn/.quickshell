import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property var logic
    property var modelData
    
    width: ListView.view ? ListView.view.width : 230
    height: 38
    
    onClicked: {
        logic.openFile(modelData.path, modelData.isDir)
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: NotesManager.currentFilePath === modelData.path ? ThemeManager.accentColor : (root.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfacePrimaryColor)
        border.color: (root.isHovered || NotesManager.currentFilePath === modelData.path) ? ThemeManager.accentColor : ThemeManager.outlineVariantColor
        border.width: 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10
        
        StyledLabel {
            text: modelData.isDir ? "󰉋" : "󰠮"
            type: "icon"
            font.pixelSize: 14
            customColor: (NotesManager.currentFilePath === modelData.path) ? ThemeManager.contentPrimaryColor : (modelData.isDir ? ThemeManager.accentColor : ThemeManager.surfaceContentColor)
        }
        
        StyledLabel {
            text: modelData.name
            type: "body"
            Layout.fillWidth: true
            elideMode: Text.ElideRight
            font.weight: NotesManager.currentFilePath === modelData.path ? Font.Bold : Font.Normal
            customColor: (NotesManager.currentFilePath === modelData.path) ? ThemeManager.contentPrimaryColor : ThemeManager.surfaceContentColor
        }
        
        BaseButton {
            width: 20
            height: 20
            visible: root.isHovered && !modelData.isDir && modelData.name !== ".."
            onClicked: {
                logic.confirmDelete(modelData.path)
            }
            
            StyledLabel {
                anchors.centerIn: parent
                text: "󰆴"
                type: "icon"
                font.pixelSize: 14
                customColor: ThemeManager.dangerColor
            }
        }
    }
}
