pragma Singleton
import QtQuick

// Will be used later in a settings widget

QtObject {
    readonly property int thickness: 15
    readonly property int cornerRadius: 10 
    readonly property color color: "#222222"
    
    readonly property int animDuration: 350
    readonly property int animEasing: Easing.OutQuint
    
    property bool leftBarExpanded: false
    property int dynamicIslandCornerRadius: 30
}
