import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property string notePath: ""
    readonly property string fileName: notePath.split('/').pop() || "Untitled"
    
    width: ListView.view ? ListView.view.width : 230
    height: 34
    
    onClicked: {
        if (root.notePath !== "") {
            NotesManager.openFile(root.notePath)
        }
    }
    
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: (NotesManager.currentFilePath === root.notePath) ? ThemeManager.surfaceVariantStrongColor : (root.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfaceSubtleColor)
        border.color: (root.isHovered || NotesManager.currentFilePath === root.notePath) ? ThemeManager.accentColor : "transparent"
        border.width: 1
        visible: root.notePath !== ""
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        z: 20
        visible: root.notePath !== ""
        
        StyledLabel {
            text: root.fileName
            type: "caption"
            customColor: ThemeManager.surfaceContentColor
            opacity: (NotesManager.currentFilePath === root.notePath) ? 1.0 : 0.7
            font.weight: (NotesManager.currentFilePath === root.notePath || root.isHovered) ? Font.DemiBold : Font.Normal
            Layout.fillWidth: true
            elideMode: Text.ElideRight
        }
        
        BaseButton {
            width: 20
            height: 20
            visible: !!(root.isHovered || NotesManager.currentFilePath === root.notePath)
            onClicked: {
                NotesManager.deleteRecent(root.notePath)
            }
            
            StyledLabel {
                anchors.centerIn: parent
                text: "󰅖"
                type: "icon"
                font.pixelSize: 12
                customColor: (NotesManager.currentFilePath === root.notePath) ? ThemeManager.accentColor : ThemeManager.dangerColor
                opacity: (NotesManager.currentFilePath === root.notePath) ? 1.0 : 0.8
            }
        }
    }
}
