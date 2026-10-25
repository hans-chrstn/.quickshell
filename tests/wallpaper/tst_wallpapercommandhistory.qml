import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperCommandHistory.js" as History

TestCase {
    name: "WallpaperCommandHistory"

    function command(id) {
        return { id: id, label: id, before: { value: 0 }, after: { value: 1 } }
    }

    function test_pushClearsRedoAndBoundsPast() {
        let state = History.empty(2)
        state = History.push(state, command("a"))
        state = History.push(state, command("b"))
        state = History.push(state, command("c"))
        compare(state.past.length, 2)
        compare(state.past[0].id, "b")
        state = History.push(state, command("d"))
        compare(state.future.length, 0)
    }

    function test_undoMovesCommandToFuture() {
        const state = History.push(History.empty(), command("a"))
        const result = History.undo(state)
        compare(result.command.id, "a")
        compare(result.state.past.length, 0)
        compare(result.state.future.length, 1)
    }

    function test_redoRestoresCommandToPast() {
        const state = History.undo(
            History.push(History.empty(), command("a"))).state
        const result = History.redo(state)
        compare(result.command.id, "a")
        compare(result.state.past.length, 1)
        compare(result.state.future.length, 0)
    }

    function test_emptyOperationsAreNoOps() {
        const state = History.empty()
        verify(History.undo(state).command === null)
        verify(History.redo(state).command === null)
        compare(History.push(state, {}).past.length, 0)
    }
}
