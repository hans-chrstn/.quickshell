import QtQuick
import QtTest
import "../../panels/wallpaper"

TestCase {
    name: "WallpaperTransitionController"

    WallpaperTransitionController {
        id: controller
    }

    SignalSpy {
        id: completedSpy
        target: controller
        signalName: "completed"
    }

    function init() {
        controller.cancel()
        completedSpy.clear()
    }

    function test_runsFromZeroToOneAndCompletesOnce() {
        controller.start(7, 80)
        verify(controller.running)
        compare(controller.generation, 7)
        compare(controller.progress, 0)
        tryCompare(controller, "running", false, 500)
        compare(controller.progress, 1)
        compare(completedSpy.count, 1)
        compare(completedSpy.signalArguments[0][0], 7)
    }

    function test_cancelStopsWithoutCompletion() {
        controller.start(8, 200)
        wait(30)
        verify(controller.progress > 0)
        controller.cancel()
        verify(!controller.running)
        compare(controller.progress, 1)
        wait(220)
        compare(completedSpy.count, 0)
    }

    function test_cancelledGenerationCannotCompleteAfterReplacement() {
        controller.start(11, 120)
        wait(30)
        controller.cancel()
        controller.start(12, 40)
        tryCompare(controller, "running", false, 300)
        compare(completedSpy.count, 1)
        compare(completedSpy.signalArguments[0][0], 12)
        wait(120)
        compare(completedSpy.count, 1)
    }

    function test_restartReplacesPriorGeneration() {
        controller.start(9, 200)
        wait(30)
        controller.start(10, 60)
        tryCompare(controller, "running", false, 500)
        compare(completedSpy.count, 1)
        compare(completedSpy.signalArguments[0][0], 10)
    }
}
