import QtQuick
import qs.core
import qs.modules.clock

IslandModule {
    moduleId: "clock"
    priority: 0
    active: true
    expandedWidth: Design.scaledWidth(330)
    expandedHeight: Design.scaledHeight(88)

    collapsedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(220)
        preferredWidth: Design.scaledWidth(220)
        maximumWidth: Design.scaledWidth(300)
        minimumHeight: Design.collapsedHeight
        preferredHeight: Design.collapsedHeight
        maximumHeight: Design.scaledHeight(56)
    }

    expandedSize: IslandSizePolicy {
        source: "intrinsic"
        minimumWidth: Design.scaledWidth(250)
        preferredWidth: Design.scaledWidth(330)
        maximumWidth: Design.scaledWidth(520)
        minimumHeight: Design.scaledHeight(64)
        preferredHeight: Design.scaledHeight(88)
        maximumHeight: Design.scaledHeight(220)
    }

    view: Component {
        ClockModule { }
    }
}
