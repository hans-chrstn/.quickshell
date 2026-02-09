pragma Singleton
import QtQuick

QtObject {
    readonly property int thickness: 15
    readonly property int cornerRadius: 25 
    readonly property color color: "#222222"
    
    readonly property int animDuration: 350
    readonly property int animEasing: Easing.OutQuint
}
