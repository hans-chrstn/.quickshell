import QtQuick
Item {
    id: root

    property QtObject context: null
    readonly property string screenName: context?.screenName ?? ""
    readonly property bool expanded: context?.expanded ?? false
    readonly property real expansionProgress: context?.expansionProgress ?? 0

    ClockCarousel {
        anchors.fill: parent
        screenName: root.screenName
        expanded: root.expanded
        expansionProgress: root.expansionProgress
    }
}
