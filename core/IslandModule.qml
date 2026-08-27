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

    property Component view
}
