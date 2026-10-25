import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperPlaylistOrder.js" as PlaylistOrder

TestCase {
    name: "WallpaperPlaylistOrder"

    readonly property var entries: [
        { id: "a", path: "/a" }, { id: "b", path: "/b" },
        { id: "c", path: "/c" }, { id: "d", path: "/d" },
        { id: "e", path: "/e" }, { id: "f", path: "/f" },
        { id: "g", path: "/g" }, { id: "h", path: "/h" }
    ]

    function ids(values) {
        return values.map(entry => entry.id).join("")
    }

    function test_orderedReturnsDefensiveCopy() {
        const playlist = { id: "test", mode: "ordered", entries: entries }
        const result = PlaylistOrder.resolvedEntries(playlist)
        compare(ids(result), "abcdefgh")
        verify(result !== entries)
        verify(result[0] !== entries[0])
        result[0].path = "/changed"
        compare(entries[0].path, "/a")
    }

    function test_seededShuffleIsDeterministicAndNonMutating() {
        const playlist = {
            id: "test", mode: "shuffle", seed: 12345, entries: entries
        }
        const first = PlaylistOrder.resolvedEntries(playlist)
        const second = PlaylistOrder.resolvedEntries(playlist)
        compare(ids(first), ids(second))
        compare(ids(entries), "abcdefgh")
        compare(first.length, entries.length)
        compare(first.map(entry => entry.id).sort().join(""), "abcdefgh")
    }

    function test_differentSeedOrNamespaceChangesOrder() {
        const first = PlaylistOrder.resolvedEntries({
            id: "test", mode: "shuffle", seed: 1, entries: entries
        })
        const second = PlaylistOrder.resolvedEntries({
            id: "test", mode: "shuffle", seed: 2, entries: entries
        })
        const namespaced = PlaylistOrder.resolvedEntries({
            id: "other", mode: "shuffle", seed: 1, entries: entries
        })
        verify(ids(first) !== ids(second))
        verify(ids(first) !== ids(namespaced))
    }

    function test_emptyAndSingleEntryAreStable() {
        compare(PlaylistOrder.resolvedEntries({
            id: "empty", mode: "shuffle", seed: 9, entries: []
        }).length, 0)
        compare(ids(PlaylistOrder.resolvedEntries({
            id: "one", mode: "shuffle", seed: 9,
            entries: [{ id: "x" }]
        })), "x")
    }
}
