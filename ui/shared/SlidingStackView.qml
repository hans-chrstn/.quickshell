import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    property int currentIndex: 0
    property int duration: ThemeManager.animationDuration
    property int easingType: ThemeManager.animationEasing
    property real slideOffset: 40
    property bool horizontal: true

    default property alias content: pageContainer.data

    Item {
        id: pageContainer
        anchors.fill: parent

        onChildrenChanged: {
            for (let i = 0; i < children.length; i++) {
                let child = children[i]
                if (!child.hasOwnProperty("_isSlidingManaged")) {
                    child.anchors.fill = pageContainer
                    
                    child.visible = Qt.binding(() => (child.opacity > 0.01))
                    child.opacity = Qt.binding(() => (root.currentIndex === i ? 1.0 : 0.0))
                    
                    let trans = Qt.createQmlObject('import QtQuick; Translate {}', child)
                    if (root.horizontal) {
                        trans.x = Qt.binding(() => (root.currentIndex === i ? 0 : (root.currentIndex > i ? -root.slideOffset : root.slideOffset)))
                    } else {
                        trans.y = Qt.binding(() => (root.currentIndex === i ? 0 : (root.currentIndex > i ? -root.slideOffset : root.slideOffset)))
                    }
                    child.transform = [trans]

                    Qt.createQmlObject('import QtQuick; Behavior on opacity { NumberAnimation { duration: ' + (root.duration * 0.8) + '; easing.type: Easing.OutQuart } }', child)
                    
                    if (root.horizontal) {
                        Qt.createQmlObject('import QtQuick; Behavior on x { NumberAnimation { duration: ' + root.duration + '; easing.type: ' + root.easingType + ' } }', trans)
                    } else {
                        Qt.createQmlObject('import QtQuick; Behavior on y { NumberAnimation { duration: ' + root.duration + '; easing.type: ' + root.easingType + ' } }', trans)
                    }

                    child._isSlidingManaged = true
                }
            }
        }
    }
}
