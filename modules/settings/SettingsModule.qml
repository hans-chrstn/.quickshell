import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

Item {
    id: root

    property QtObject context: null
    focus: true

    Component.onCompleted: {
        forceActiveFocus();
        focusTimer.start();
    }

    Timer {
        id: focusTimer
        property int attempts: 0
        interval: 100
        onTriggered: {
            if (!SettingsService.opened)
                return;
            root.forceActiveFocus();
            if (!root.activeFocus && attempts < 6) {
                attempts += 1;
                restart();
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            SettingsService.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            SettingsService.selectedCategory = Math.max(0, SettingsService.selectedCategory - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            SettingsService.selectedCategory = Math.min(SettingsService.categories.length - 1, SettingsService.selectedCategory + 1);
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: categoryRail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 96
        spacing: 6

        Text {
            text: "Settings"
            color: Design.text
            font.family: Design.fontDisplay
            font.pixelSize: 20
            font.weight: Font.DemiBold
            Layout.leftMargin: 10
            Layout.bottomMargin: 8
        }

        Repeater {
            model: SettingsService.categories

            delegate: Rectangle {
                id: category
                required property int index
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 10
                color: index === SettingsService.selectedCategory ? Design.surfaceRaised : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: category.modelData.title
                    color: category.index === SettingsService.selectedCategory ? Design.text : Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                    TapHandler {
                        onTapped: SettingsService.selectedCategory = category.index
                    }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Rectangle {
        id: divider
        anchors.left: categoryRail.right
        anchors.leftMargin: 10
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Design.separator
    }

    Loader {
        anchors.left: divider.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        sourceComponent: SettingsService.selectedCategory === 0
            ? motionPage : SettingsService.selectedCategory === 1
                ? behaviorPage : wallpaperPage
    }

    Component {
        id: motionPage
        MotionSettingsPage {}
    }
    Component {
        id: behaviorPage
        BehaviorSettingsPage {}
    }
    Component {
        id: wallpaperPage
        WallpaperSettingsPage {}
    }
}
