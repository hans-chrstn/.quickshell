import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperPlaylistModel.js" as PlaylistModel

TestCase {
    name: "WallpaperPlaylistModel"

    function test_normalizesVersionModesIdsAndEntries() {
        const result = PlaylistModel.normalizeDocument({
            schemaVersion: 99,
            playlists: [
                {
                    id: "focus",
                    name: "  Focus  ",
                    mode: "shuffle",
                    seed: 42.8,
                    entries: [
                        { id: "same", path: " /a.png ", durationMs: 500 },
                        { id: "same", path: "/b.mp4", durationMs: 2500 },
                        { path: "", durationMs: 5000 }
                    ]
                },
                { id: "focus", mode: "invalid", entries: [] }
            ]
        })

        compare(result.schemaVersion, 1)
        compare(result.playlists.length, 2)
        compare(result.playlists[0].name, "Focus")
        compare(result.playlists[0].mode, "shuffle")
        compare(result.playlists[0].seed, 42)
        compare(result.playlists[0].entries.length, 2)
        compare(result.playlists[0].entries[0].durationMs, 1000)
        compare(result.playlists[0].entries[1].durationMs, 2500)
        verify(result.playlists[0].entries[0].id
            !== result.playlists[0].entries[1].id)
        compare(result.playlists[1].id, "focus-2")
        compare(result.playlists[1].mode, "ordered")
    }

    function test_optionalDurationAndDefaults() {
        const result = PlaylistModel.normalizeDocument({
            playlists: [{ entries: [{ path: "/wall.gif" }] }]
        })
        const playlist = result.playlists[0]
        compare(playlist.id, "playlist-1")
        compare(playlist.name, "Untitled Playlist")
        compare(playlist.entries[0].durationMs, 0)
    }

    function test_collectionBounds() {
        const playlists = []
        for (let playlistIndex = 0; playlistIndex < 70; ++playlistIndex) {
            const entries = []
            for (let entryIndex = 0; entryIndex < 520; ++entryIndex)
                entries.push({ path: "/" + playlistIndex + "/" + entryIndex })
            playlists.push({ entries: entries })
        }
        const result = PlaylistModel.normalizeDocument({ playlists: playlists })
        compare(result.playlists.length, 64)
        compare(result.playlists[0].entries.length, 512)
        compare(result.playlists[3].entries.length, 512)
        compare(result.playlists[4].entries.length, 0)
        compare(result.playlists[63].entries.length, 0)
    }
}
