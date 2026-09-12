import QtQuick

QtObject {
    id: root

    required property string moduleId

    property int priority: 0
    property bool active: false
    property bool attention: false
    property bool wantsKeyboard: false

    property int collapsedWidth: Design.collapsedWidth
    property int expandedWidth: Design.defaultExpandedWidth
    property int expandedHeight: Design.defaultExpandedHeight

    property IslandSizePolicy collapsedSize: IslandSizePolicy {
        minimumWidth: root.collapsedWidth
        preferredWidth: root.collapsedWidth
        maximumWidth: root.collapsedWidth
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.collapsedHeight
    }

    property IslandSizePolicy expandedSize: IslandSizePolicy {
        minimumWidth: root.expandedWidth
        preferredWidth: root.expandedWidth
        maximumWidth: root.expandedWidth
        minimumHeight: root.expandedHeight
        preferredHeight: root.expandedHeight
        maximumHeight: root.expandedHeight
    }
    property bool revealWithExpansion: false
    property real revealStart: 0.22
    property real revealEnd: 0.72

    property Component view
}
