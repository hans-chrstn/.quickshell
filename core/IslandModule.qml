import QtQuick

QtObject {
    required property string moduleId

    property int priority: 0
    property bool active: false
    property bool attention: false
    property bool wantsKeyboard: false

    property int collapsedWidth: Design.collapsedWidth
    property int expandedWidth: Design.defaultExpandedWidth
    property int expandedHeight: Design.defaultExpandedHeight

    property bool revealWithExpansion: false
    property real revealStart: 0.22
    property real revealEnd: 0.72
    property real revealOffsetY: -8

    property Component view
}
