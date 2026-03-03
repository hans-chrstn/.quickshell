import QtQuick
import qs.core

Item {
    id: root
    
    anchors.fill: parent

    Loader {
        id: visualizerLoader
        anchors.fill: parent
        
        source: {
            if (ThemeManager.visualizerStyle === 0) {
                return "TraditionalVisualizer.qml"
            }
            if (ThemeManager.visualizerStyle === 1) {
                return "LiquidWaveVisualizer.qml"
            }
            return ""
        }
    }
}
