import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared
import qs.ui.shared.config

Loader {
    id: root
    
    width: parent ? parent.width : 0
    asynchronous: true
    
    property var configurationItemData: null
    property bool labelVisible: true

    readonly property bool isCurrentlyFocused: item && item.activeFocus

    onActiveFocusChanged: {
        if (activeFocus && ListView.view) {
            ListView.view.currentIndex = index
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isCurrentlyFocused ? 0.05 : 0
        border.color: ThemeManager.accentColor
        border.width: root.isCurrentlyFocused ? 1 : 0
        z: -1
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }

    sourceComponent: {
        if (!configurationItemData) {
            return null
        }
        switch (configurationItemData.type) {
            case "header": {
                return headerComp
            }
            case "slider": {
                return sliderComp
            }
            case "color": {
                return colorComp
            }
            case "switch": {
                return switchComp
            }
            case "text": {
                return textComp
            }
            case "action": {
                return actionComp
            }
            case "gesture_editor": {
                return gestureEditorComp
            }
            default: {
                return null
            }
        }
    }

    Component {
        id: actionComp
        ConfigActionItem {
            configurationItemData: root.configurationItemData
        }
    }

    Component {
        id: textComp
        ConfigTextItem {
            configurationItemData: root.configurationItemData
        }
    }

    Component {
        id: headerComp
        ConfigHeaderItem {
            configurationItemData: root.configurationItemData
        }
    }

    Component {
        id: sliderComp
        ConfigSliderItem {
            configurationItemData: root.configurationItemData
        }
    }

    Component {
        id: switchComp
        ConfigSwitchItem {
            configurationItemData: root.configurationItemData
        }
    }

    Component {
        id: colorComp
        ConfigColorItem {
            configurationItemData: root.configurationItemData
        }
    }

    Component {
        id: gestureEditorComp
        ConfigGestureEditorItem {
            configurationItemData: root.configurationItemData
        }
    }
}
