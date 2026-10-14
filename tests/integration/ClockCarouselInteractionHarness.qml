import QtQuick
import QtTest
import Quickshell
import qs.modules.clock

ShellRoot {
    Window {
        id: window

        width: 420
        height: 140
        visible: true

        ClockCarousel {
            id: carousel

            anchors.centerIn: parent
            width: 330
            height: 88
            screenName: "clock-carousel-test"
            presented: true
        }

        TestCase {
            name: "ClockCarouselInteraction"
            when: window.visible

            property var pagesView: null
            property var wheelHandler: null

            function initTestCase() {
                pagesView = findChild(carousel, "clockCarouselPages");
                wheelHandler = findChild(carousel, "clockCarouselWheelHandler");
                verify(pagesView !== null);
                verify(wheelHandler !== null);
            }

            function init() {
                carousel.presented = true;
                carousel.expanded = false;
                carousel.expansionProgress = 0;
                carousel.restoreClockPage();
                wait(0);
            }

            function test_navigationRequiresCompletedExpansion() {
                carousel.expanded = true;
                carousel.expansionProgress = 0.5;
                wait(0);

                verify(!carousel.navigationEnabled);
                verify(!pagesView.interactive);
                verify(!wheelHandler.enabled);
                compare(pagesView.currentIndex, 1);

                carousel.step(1);
                compare(pagesView.currentIndex, 1);

                carousel.expansionProgress = 0.998;
                wait(0);
                verify(!carousel.navigationEnabled);
                carousel.step(1);
                compare(pagesView.currentIndex, 1);

                carousel.expansionProgress = 1;
                wait(0);
                verify(carousel.navigationEnabled);
                verify(pagesView.interactive);
                verify(wheelHandler.enabled);

                carousel.step(1);
                compare(pagesView.currentIndex, 2);

                carousel.expanded = false;
                wait(0);
                verify(!carousel.navigationEnabled);
                verify(!pagesView.interactive);
                verify(!wheelHandler.enabled);
            }

            function test_collapsedPageRestoresWhenProgressChangesFirst() {
                carousel.expanded = true;
                carousel.expansionProgress = 1;
                pagesView.currentIndex = 3;
                wait(0);
                compare(pagesView.currentIndex, 3);

                carousel.presented = false;
                carousel.expansionProgress = 0;
                carousel.expanded = false;
                wait(0);

                compare(pagesView.currentIndex, 1);
                verify(!carousel.returningToClock);

                carousel.presented = true;
                wait(0);
                compare(pagesView.currentIndex, 1);
            }

            function test_collapsedPageRestoresWhenExpandedChangesFirst() {
                carousel.expanded = true;
                carousel.expansionProgress = 1;
                pagesView.currentIndex = 3;
                wait(0);

                carousel.presented = false;
                carousel.expanded = false;
                verify(carousel.returningToClock);
                carousel.expansionProgress = 0;
                wait(0);

                compare(pagesView.currentIndex, 1);
                verify(!carousel.returningToClock);
            }
        }
    }
}
