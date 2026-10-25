import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperScrubRequest.js" as Scrub

TestCase {
    name: "WallpaperScrubRequest"

    function test_requestNormalization() {
        const first = Scrub.request(1, "/tmp/a.mp4", 120)
        verify(first.valid && first.positionMs === 120)
        verify(!Scrub.request(2, "", 1).valid)
        compare(Scrub.request(3, "/tmp/a.mp4", -4).positionMs, 0)
        verify(Scrub.completionIsCurrent(first, {
            generation: 1, path: "/tmp/a.mp4", positionMs: 120
        }))
        verify(!Scrub.completionIsCurrent(first, {
            generation: 0, path: "/tmp/a.mp4", positionMs: 120
        }))
        verify(!Scrub.completionIsCurrent(first, {
            generation: 1, path: "/tmp/b.mp4", positionMs: 120
        }))
        compare(Scrub.nextGeneration(4), 5)
    }
}
