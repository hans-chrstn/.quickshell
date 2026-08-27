import QtQuick
import qs.core
import qs.modules.clock

IslandModule {
    moduleId: "clock"
    priority: 0
    active: true

    view: Component {
        ClockModule { }
    }
}
