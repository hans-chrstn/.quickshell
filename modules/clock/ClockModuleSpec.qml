import QtQuick
import qs.core
import qs.modules.clock

IslandModule {
    moduleId: "clock"
    priority: 0
    active: true
    expandedWidth: 280
    expandedHeight: 68

    view: Component {
        ClockModule { }
    }
}
