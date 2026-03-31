import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root
    height: parent.height
    spacing: 6
    
    property string screenName: ""
    property var screen: null

    HoverHandler {
        onHoveredChanged: {
            ViewManager.indicatorHovered = hovered
        }
    }

    Repeater {
        model: NiriManager.workspaces
        delegate: Rectangle {
            id: indicator
            readonly property bool onCurrentScreen: model.output === root.screenName
            visible: onCurrentScreen
            
            function updateRegistration() {
                if (!visible || !root.screenName || !root.screen) return
                let pos = indicator.mapToItem(null, 0, 0)
                let gx = root.screen.x + pos.x
                let gy = root.screen.y + pos.y
                
                let ref = (model.name && model.name !== "") ? model.name : model.index.toString()
                ViewManager.registerIndicator(model.id, ref, Qt.rect(gx, gy, width, height))
            }

            onXChanged: updateRegistration()
            onWidthChanged: updateRegistration()
            onVisibleChanged: updateRegistration()
            Component.onCompleted: updateRegistration()

            readonly property bool isTargeted: ViewManager.activeDragWindowId !== -1 && ViewManager.hoveredTargetWorkspaceId === model.id
            readonly property bool isMasterHovered: ViewManager.hoveredWorkspaceId === model.id || isTargeted

            Layout.preferredWidth: visible ? (isMasterHovered ? 32 : (model.isActive ? 24 : 8)) : 0
            Layout.preferredHeight: visible ? 6 : 0

            radius: 3
            color: isTargeted ? "white" : (model.isFocused ? ThemeManager.accentColor : 
                   model.isActive ? Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.5) : 
                                    Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.2))

            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

            MouseArea {
                id: maWs
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: ViewManager.activeDragWindowId !== -1 ? Qt.DragCopyCursor : Qt.PointingHandCursor
                onClicked: NiriManager.focusWorkspaceById(model.id)

                onEntered: {
                    if (ViewManager.activeDragWindowId === -1) {
                        NiriManager.forceUpdateLayouts()
                        ViewManager.setHoveredWorkspace(model.id)
                    }
                }

                onExited: {
                    if (ViewManager.activeDragWindowId === -1) {
                        ViewManager.setHoveredWorkspace(-1)
                    }
                }
            }
        }
    }
}
