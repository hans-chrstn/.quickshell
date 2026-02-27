import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import qs.core

QQC2.Label {
    id: root
    
    property string type: "label"
    
    property color customColor: ThemeManager.contentOnBackgroundColor
    
    color: customColor
    
    font {
        pixelSize: ThemeManager.typography[type].pixelSize
        weight: ThemeManager.typography[type].weight
        letterSpacing: ThemeManager.typography[type].letterSpacing
        pointSize: -1
    }
    
    property alias weight: root.font.weight
    property alias pixelSize: root.font.pixelSize
    property alias pointSize: root.font.pointSize
    property alias italic: root.font.italic
    property alias letterSpacing: root.font.letterSpacing
    property alias elideMode: root.elide
}
