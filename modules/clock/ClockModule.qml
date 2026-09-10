import QtQuick
Item {
    id: root

    property QtObject context: null
    readonly property string screenName: context?.screenName ?? ""
    readonly property bool presented: context?.presented ?? false
    readonly property bool expanded: context?.expanded ?? false
    readonly property real expansionProgress: context?.expansionProgress ?? 0
    readonly property real collapsedImplicitWidth:
        carousel.collapsedImplicitWidth
    readonly property real collapsedImplicitHeight:
        carousel.collapsedImplicitHeight
    readonly property real expandedImplicitWidth:
        carousel.expandedImplicitWidth
    readonly property real expandedImplicitHeight:
        carousel.expandedImplicitHeight

    ClockCarousel {
        id: carousel
        anchors.fill: parent
        screenName: root.screenName
        presented: root.presented
        expanded: root.expanded
        expansionProgress: root.expansionProgress
    }
}
