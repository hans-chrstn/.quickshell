import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperHookModel.js" as Hooks

TestCase {
    name: "WallpaperHookModel"

    function normalized(values) {
        return Hooks.normalizeDocument({ hooks: values }).hooks
    }

    function test_hooksAreExplicitlyOptInAndRequireAbsoluteExecutable() {
        const hooks = normalized([
            { id: "disabled", phase: "pre-change", executable: "/bin/true" },
            { id: "relative", enabled: true, phase: "pre-change",
                executable: "notify-send" },
            { id: "invalid-phase", enabled: true, phase: "during",
                executable: "/bin/true" }
        ])
        compare(hooks.length, 1)
        verify(!hooks[0].enabled)
        compare(Hooks.invocation(hooks[0], {}), null)
    }

    function test_invocationUsesArgumentArrayAndLiteralUnusualPaths() {
        const hook = normalized([{ id: "safe", enabled: true,
            phase: "post-change", executable: "/usr/bin/helper",
            arguments: ["--screen={screen}", "{path}", "{unknown}"],
            timeoutMs: 9000 }])[0]
        const hostile = "/wall papers/$(touch nope);'quoted'.png"
        const result = Hooks.invocation(hook, {
            screen: "DP-1", path: hostile
        })
        compare(result.command.length, 4)
        compare(result.command[0], "/usr/bin/helper")
        compare(result.command[1], "--screen=DP-1")
        compare(result.command[2], hostile)
        compare(result.command[3], "{unknown}")
        compare(result.timeoutMs, 9000)
    }

    function test_selectionUsesPhaseScopePriorityAndStableId() {
        const hooks = normalized([
            { id: "global", enabled: true, phase: "pre-change",
                executable: "/bin/true", priority: 5 },
            { id: "z-screen", enabled: true, phase: "pre-change",
                executable: "/bin/true", screenName: "DP-3", priority: 8 },
            { id: "a-screen", enabled: true, phase: "pre-change",
                executable: "/bin/true", screenName: "DP-3", priority: 8 },
            { id: "post", enabled: true, phase: "post-change",
                executable: "/bin/true", priority: 100 }
        ])
        const selected = Hooks.selected(hooks, "pre-change", "DP-3")
        compare(selected.length, 3)
        compare(selected[0].id, "a-screen")
        compare(selected[1].id, "z-screen")
        compare(selected[2].id, "global")
        compare(Hooks.selected(hooks, "pre-change", "DP-1").length, 1)
    }

    function test_normalizationBoundsDocumentArgumentsAndTimeouts() {
        const values = []
        for (let index = 0; index < Hooks.maximumHooks + 10; ++index) {
            values.push({ id: "same", enabled: true, phase: "pre-change",
                executable: "/bin/true",
                arguments: new Array(Hooks.maximumArguments + 5).fill("x"),
                timeoutMs: index === 0 ? -1 : 999999,
                priority: 999999 })
        }
        const hooks = normalized(values)
        compare(hooks.length, Hooks.maximumHooks)
        compare(hooks[0].arguments.length, Hooks.maximumArguments)
        compare(hooks[0].timeoutMs, Hooks.minimumTimeoutMs)
        compare(hooks[1].timeoutMs, Hooks.maximumTimeoutMs)
        compare(hooks[0].priority, 1000)
        compare(hooks[1].id, "same-2")
        values[0].arguments[0] = "changed"
        compare(hooks[0].arguments[0], "x")
    }

    function test_contextIsAllowlistedAndBounded() {
        const context = Hooks.boundedContext({
            path: "x".repeat(5000), secret: "not exposed"
        })
        compare(context.path.length, 4096)
        verify(context.secret === undefined)
        compare(Hooks.expandArgument("{secret}:{path}", { path: "ok",
            secret: "value" }), "{secret}:ok")
    }
}
