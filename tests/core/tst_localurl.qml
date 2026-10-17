import QtQuick
import QtTest
import "../../core/LocalUrl.js" as LocalUrl

TestCase {
    name: "LocalUrl"

    function test_emptyPath() {
        compare(LocalUrl.fromPath(""), "")
    }

    function test_absolutePath() {
        compare(LocalUrl.fromPath("/home/user/My Wallpaper.png"),
            "file:///home/user/My%20Wallpaper.png")
    }

    function test_reservedCharacters() {
        compare(LocalUrl.fromPath("/tmp/foo#bar?.mp4"),
            "file:///tmp/foo%23bar%3F.mp4")
    }

    function test_existingFileUrl() {
        compare(LocalUrl.fromPath("file:///tmp/already%20encoded.png"),
            "file:///tmp/already%20encoded.png")
    }
}
