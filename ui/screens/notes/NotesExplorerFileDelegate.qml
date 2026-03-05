import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property var logic
    
    width: ListView.view ? ListView.view.width : 230
    height: 38
    
    onClicked: {
        logic.openFile(path, isDir)
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: (NotesManager.currentFilePath === path) ? ThemeManager.surfaceVariantStrongColor : (root.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfaceSubtleColor)
        border.color: (root.isHovered || NotesManager.currentFilePath === path) ? ThemeManager.accentColor : ThemeManager.outlineVariantColor
        border.width: 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10
        
        StyledLabel {
            text: isDir ? "󰉋" : "󰠮"
            type: "icon"
            font.pixelSize: 14
            customColor: isDir ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
            opacity: (NotesManager.currentFilePath === path) ? 1.0 : 0.7
        }
        
        StyledLabel {
            text: name
            type: "body"
            Layout.fillWidth: true
            elideMode: Text.ElideRight
            font.weight: (NotesManager.currentFilePath === path) ? Font.Bold : Font.Normal
            customColor: ThemeManager.surfaceContentColor
            opacity: (NotesManager.currentFilePath === path) ? 1.0 : 0.8
        }
        
        BaseButton {
            width: 20
            height: 20
            visible: !!(root.isHovered && !isDir && name !== "..")
            onClicked: {
                logic.confirmDelete(path)
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
