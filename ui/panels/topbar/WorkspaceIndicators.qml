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
        model: WindowManager.workspaces
        delegate: Rectangle {
            id: indicator
            property var ws: WindowManager.getWorkspaceProps(modelData)
            readonly property bool onCurrentScreen: ws && ws.output === root.screenName
            visible: onCurrentScreen
            
            function updateRegistration() {
                if (!visible || !root.screenName || !root.screen) return
                let pos = indicator.mapToItem(null, 0, 0)
                let gx = root.screen.x + pos.x
                let gy = root.screen.y + pos.y
                
                let ref = (ws.name && ws.name !== "") ? ws.name : ws.id.toString()
                ViewManager.registerIndicator(ws.id, ref, Qt.rect(gx, gy, width, height))
            }

            onXChanged: updateRegistration()
            onWidthChanged: updateRegistration()
            onVisibleChanged: updateRegistration()
            Component.onCompleted: updateRegistration()

            readonly property bool isTargeted: ViewManager.isDragging && ws && ViewManager.hoveredTargetWorkspaceId === ws.id
            readonly property bool isMasterHovered: ws && (ViewManager.hoveredWorkspaceId === ws.id || isTargeted)

            Layout.preferredWidth: visible && ws ? (isMasterHovered ? 32 : (ws.isActive ? 24 : 8)) : 0
            Layout.preferredHeight: visible ? 6 : 0

            radius: 3
            color: isTargeted ? "white" : (ws && ws.isFocused ? ThemeManager.accentColor : 
                   ws && ws.isActive ? Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.5) : 
                                       Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.2))

            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

            MouseArea {
                id: maWs
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: ViewManager.isDragging ? Qt.DragCopyCursor : Qt.PointingHandCursor
                onClicked: WindowManager.focusWorkspaceById(ws.id)

                onEntered: {
                    if (!ViewManager.isDragging && ws) {
                        WindowManager.forceUpdateLayouts()
                        ViewManager.setHoveredWorkspace(ws.id)
                    }
                }

                onExited: {
                    if (!ViewManager.isDragging) {
                        ViewManager.setHoveredWorkspace(-1)
                    }
                }
            }
        }
    }
}
