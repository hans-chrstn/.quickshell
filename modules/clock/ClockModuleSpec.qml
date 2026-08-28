import QtQuick
import qs.core
import qs.modules.clock

IslandModule {
    moduleId: "clock"
    priority: 0
    active: true
    expandedWidth: Design.scaledWidth(280)
    expandedHeight: Design.scaledHeight(68)

    view: Component {
        ClockModule { }
    }
}
