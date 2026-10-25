import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftDerivativeCommand.js" as Command
import "../../services/wallpaper/projects/WallpaperDraftDerivativePlan.js" as Plan

TestCase {
    name: "WallpaperDraftDerivativeCommand"

    function fixture(role, recipe) {
        return { role: role, recipe: recipe,
            sourcePath: "/draft/media/source.mp4",
            temporaryPath: "/draft/" + role + "/output.partial" }
    }

    function test_thumbnailIsBoundedSingleFrameAndArgumentSafe() {
        const command = Command.create("/usr/bin/ffmpeg",
            fixture("thumbnail", Plan.thumbnailRecipe))
        compare(command[0], "/usr/bin/ffmpeg")
        verify(command.indexOf("-frames:v") >= 0)
        verify(command.indexOf("1") >= 0)
        verify(command.indexOf("-an") >= 0)
        verify(command.indexOf("/draft/media/source.mp4") >= 0)
        compare(Command.timeoutFor("thumbnail"), 30000)
    }

    function test_proxyIsSilentBoundedAndHardwareFriendly() {
        const command = Command.create("/usr/bin/ffmpeg",
            fixture("proxy", Plan.proxyRecipe))
        verify(command.indexOf("libx264") >= 0)
        verify(command.indexOf("yuv420p") >= 0)
        verify(command.indexOf("-an") >= 0)
        verify(command.some(value => value.indexOf("fps=24") >= 0))
        compare(Command.timeoutFor("proxy"), 600000)
    }

    function test_rejectsUnknownRecipeRoleAndRelativePaths() {
        verify(Command.create("ffmpeg",
            fixture("thumbnail", Plan.thumbnailRecipe)).length === 0)
        verify(Command.create("/usr/bin/ffmpeg",
            fixture("media", Plan.thumbnailRecipe)).length === 0)
        verify(Command.create("/usr/bin/ffmpeg",
            fixture("thumbnail", "unknown")).length === 0)
        const relative = fixture("thumbnail", Plan.thumbnailRecipe)
        relative.temporaryPath = "relative.png"
        verify(Command.create("/usr/bin/ffmpeg", relative).length === 0)
        compare(Command.timeoutFor("media"), 0)
    }
}
