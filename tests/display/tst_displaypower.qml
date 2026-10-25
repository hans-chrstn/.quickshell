import QtQuick
import QtTest
import DisplayPower

TestCase {
    id: root
    name: "DisplayPowerObserver"
    when: true

    DisplayPowerObserver {
        id: observer
    }

    function test_connectionLifecycle() {
        compare(observer.enabled, false);
        compare(observer.available, false);
        compare(Object.keys(observer.screens).length, 0);
        for (let cycle = 0; cycle < 20; ++cycle) {
            observer.enabled = true;
            tryCompare(observer, "available", true, 3000);
            tryVerify(function () {
                return Object.keys(observer.screens).length > 0;
            }, 3000);
            compare(observer.error, "");
            const snapshot = observer.screens;
            const name = Object.keys(snapshot)[0];
            const initial = observer.screens[name];
            snapshot[name] = !initial;
            compare(observer.screens[name], initial);
            observer.enabled = false;
            compare(observer.available, false);
            compare(Object.keys(observer.screens).length, 0);
        }
    }
}
