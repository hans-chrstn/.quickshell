import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperPreviewState.js" as Preview

TestCase {
    name: "WallpaperPreviewState"

    function state(values) {
        return Object.assign({ durationMs: 10000, positionMs: 0,
            playing: false, loopEnabled: false, loopStartMs: 0,
            loopEndMs: 10000 }, values || {})
    }

    function test_normalizesBoundsAndDisablesEmptyPlayback() {
        const result = Preview.normalize({ durationMs: -1, positionMs: 99,
            playing: true, loopStartMs: 8, loopEndMs: 2 })
        compare(result.durationMs, 0)
        compare(result.positionMs, 0)
        verify(!result.playing)
        verify(!result.loopEnabled)
        compare(result.loopStartMs, 0)
        compare(result.loopEndMs, 0)
    }

    function test_playPauseAndSeekAreImmutableAndBounded() {
        const original = state({ positionMs: 2000 })
        const played = Preview.play(original)
        verify(played.playing)
        const sought = Preview.seek(played, 50000)
        compare(sought.positionMs, 10000)
        verify(!sought.playing)
        verify(!original.playing)
        verify(Preview.pause(played).playing === false)
    }

    function test_playAtEndDoesNotRestartWithoutLoop() {
        verify(!Preview.play(state({ positionMs: 10000 })).playing)
        verify(Preview.play(state({ positionMs: 10000, loopEnabled: true,
            loopStartMs: 2000, loopEndMs: 10000 })).playing)
    }

    function test_loopSelectionClampsAndRepositions() {
        const result = Preview.setLoop(state({ positionMs: 9000 }), true, 2000, 8000)
        verify(result.loopEnabled)
        compare(result.loopStartMs, 2000)
        compare(result.loopEndMs, 8000)
        compare(result.positionMs, 2000)
        const invalid = Preview.setLoop(result, true, 8000, 8000)
        verify(!invalid.loopEnabled)
    }

    function test_advancePausedDoesNothing() {
        const result = Preview.advance(state({ positionMs: 1000 }), 500)
        compare(result.state.positionMs, 1000)
        verify(!result.wrapped && !result.reachedEnd)
    }

    function test_advancePlayingWithinDuration() {
        const result = Preview.advance(Preview.play(state({ positionMs: 1000 })), 500)
        compare(result.state.positionMs, 1500)
        verify(result.state.playing)
        verify(!result.wrapped && !result.reachedEnd)
    }

    function test_advanceStopsAtEnd() {
        const result = Preview.advance(Preview.play(state({ positionMs: 9000 })), 1500)
        compare(result.state.positionMs, 10000)
        verify(!result.state.playing)
        verify(result.reachedEnd)
    }

    function test_advanceWrapsWithinLoopRegion() {
        const playing = Preview.play(state({ positionMs: 7500, loopEnabled: true,
            loopStartMs: 2000, loopEndMs: 8000 }))
        const result = Preview.advance(playing, 1000)
        compare(result.state.positionMs, 2500)
        verify(result.state.playing && result.wrapped)
        verify(!result.reachedEnd)
    }

    function test_largeLoopElapsedUsesDeterministicModulo() {
        const result = Preview.advance(Preview.play(state({ positionMs: 3000,
            loopEnabled: true, loopStartMs: 2000, loopEndMs: 5000 })), 10001)
        compare(result.state.positionMs, 4001)
        verify(result.wrapped)
    }

    function test_loopEndIsExclusiveAtBoundary() {
        const result = Preview.advance(Preview.play(state({ positionMs: 7999,
            loopEnabled: true, loopStartMs: 2000, loopEndMs: 8000 })), 1)
        compare(result.state.positionMs, 2000)
        verify(result.wrapped)
    }

    function test_seekPreservesPlaybackBeforeEnd() {
        const result = Preview.seek(Preview.play(state()), 5000)
        compare(result.positionMs, 5000)
        verify(result.playing)
    }

    function test_seekEndPausesWithoutLoop() {
        const result = Preview.seek(Preview.play(state()), 10000)
        verify(!result.playing)
    }

    function test_loopSeekOutsideRegionUsesStart() {
        const result = Preview.seek(Preview.setLoop(state(), true, 3000, 7000), 9000)
        compare(result.positionMs, 9000)
        const configured = Preview.setLoop(state({ positionMs: 9000 }), true, 3000, 7000)
        compare(configured.positionMs, 3000)
    }

    function test_nonFiniteElapsedIsNoOp() {
        const result = Preview.advance(Preview.play(state({ positionMs: 1000 })), NaN)
        compare(result.state.positionMs, 1000)
        verify(!result.reachedEnd)
    }
}
