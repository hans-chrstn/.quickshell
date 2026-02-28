import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import qs.core

QQC2.Label {
    id: root
    
    property string type: "body"
    
    property color customColor: ThemeManager.contentOnBackgroundColor
    
    color: customColor
    
    font {
        family: ThemeManager.fontFamily
        pixelSize: ThemeManager.typography[type] ? ThemeManager.typography[type].pixelSize : 14
        weight: ThemeManager.typography[type] ? ThemeManager.typography[type].weight : Font.Normal
        letterSpacing: ThemeManager.typography[type] ? ThemeManager.typography[type].letterSpacing : 0
        pointSize: -1
    }
    
    property alias weight: root.font.weight
    property alias pixelSize: root.font.pixelSize
    property alias pointSize: root.font.pointSize
    property alias italic: root.font.italic
    property alias letterSpacing: root.font.letterSpacing
    property alias elideMode: root.elide
}
