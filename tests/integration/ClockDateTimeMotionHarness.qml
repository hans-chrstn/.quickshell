import QtQuick
import QtTest
import Quickshell
import qs.modules.clock

ShellRoot {
    Window {
        id: window

        width: 360
        height: 140
        visible: true

        ClockDateTimeView {
            id: clock

            anchors.centerIn: parent
            width: expandedImplicitWidth
            height: expandedImplicitHeight
        }

        TestCase {
            name: "ClockDateTimeMotion"
            when: window.visible

            property var dateColumn: null
            property var divider: null
            property var timeText: null

            function timeCenterX() {
                return timeText.x + timeText.width / 2;
            }

            function initTestCase() {
                dateColumn = findChild(clock, "clockDateColumn");
                divider = findChild(clock, "clockDateDivider");
                timeText = findChild(clock, "clockTimeText");
                verify(dateColumn !== null);
                verify(divider !== null);
                verify(timeText !== null);
            }

            function test_collapsedTimeOwnsTheCenter() {
                clock.expansionProgress = 0;
                wait(0);

                compare(dateColumn.opacity, 0);
                compare(divider.opacity, 0);
                compare(timeText.scale, clock.collapsedScale);
                fuzzyCompare(timeCenterX(), clock.width / 2, 0.01);
            }

            function test_expansionMakesRoomForTheDate() {
                clock.expansionProgress = 0;
                wait(0);
                const collapsedTimeCenter = timeCenterX();
                const collapsedDateX = dateColumn.x;

                clock.expansionProgress = 0.5;
                wait(0);
                verify(dateColumn.opacity > 0 && dateColumn.opacity < 1);
                verify(divider.opacity > 0 && divider.opacity < 1);
                verify(dateColumn.x > collapsedDateX);
                verify(timeCenterX() > collapsedTimeCenter);
                verify(timeText.scale > clock.collapsedScale);
                verify(timeText.scale < 1);

                clock.expansionProgress = 1;
                wait(0);
                compare(dateColumn.opacity, 1);
                compare(divider.opacity, 1);
                compare(dateColumn.x, 0);
                compare(timeText.scale, 1);
                verify(timeCenterX() > collapsedTimeCenter);
                fuzzyCompare(timeText.x, divider.x + divider.width + 22, 0.01);
            }

            function test_retractionUsesTheSameProgressPath() {
                clock.expansionProgress = 1;
                wait(0);
                const expandedTimeCenter = timeCenterX();

                clock.expansionProgress = 0.5;
                wait(0);
                const midpointTimeCenter = timeCenterX();
                verify(midpointTimeCenter < expandedTimeCenter);

                clock.expansionProgress = 0;
                wait(0);
                compare(dateColumn.opacity, 0);
                compare(divider.opacity, 0);
                verify(timeCenterX() < midpointTimeCenter);
                fuzzyCompare(timeCenterX(), clock.width / 2, 0.01);
            }

            function test_progressIsBounded() {
                clock.expansionProgress = -4;
                wait(0);
                compare(clock.progress, 0);
                compare(dateColumn.opacity, 0);

                clock.expansionProgress = 7;
                wait(0);
                compare(clock.progress, 1);
                compare(dateColumn.opacity, 1);
                compare(timeText.scale, 1);
            }
        }
    }
}
