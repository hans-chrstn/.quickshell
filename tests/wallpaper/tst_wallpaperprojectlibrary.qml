import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperProjectLibrary.js" as Library

TestCase {
    name: "WallpaperProjectLibrary"

    function project(id) {
        return { schemaVersion: 1, project: { id: id, name: id,
            assets: [], tracks: [], markers: [], userProperties: [],
            outputTargets: [] } }
    }

    function test_parsesAndClearsStaleSelection() {
        const parsed = Library.parse({ schemaVersion: 1,
            activeProjectId: "missing", projects: [project("one")] })
        verify(parsed.accepted)
        compare(parsed.document.projects.length, 1)
        compare(parsed.document.activeProjectId, "")
    }

    function test_upsertReplacesByStableIdWithoutMutatingInput() {
        const original = { schemaVersion: 1, activeProjectId: "one",
            projects: [project("one")] }
        const replacement = project("one")
        replacement.project.name = "Changed"
        const result = Library.upsert(original, replacement)
        verify(result.accepted)
        compare(result.document.projects.length, 1)
        compare(result.document.projects[0].project.name, "Changed")
        compare(original.projects[0].project.name, "one")
    }

    function test_rejectsDuplicatesInvalidProjectsAndOverflow() {
        verify(!Library.parse({ schemaVersion: 1,
            projects: [project("one"), project("one")] }).accepted)
        verify(!Library.parse({ schemaVersion: 1,
            projects: [{ schemaVersion: 9, project: {} }] }).accepted)
        const projects = []
        for (let index = 0; index <= Library.maximumProjects; ++index)
            projects.push(project("project-" + index))
        verify(!Library.parse({ schemaVersion: 1, projects: projects }).accepted)
    }

    function test_removeClearsActiveAndRejectsUnknown() {
        const document = { schemaVersion: 1, activeProjectId: "one",
            projects: [project("one"), project("two")] }
        const removed = Library.remove(document, "one")
        verify(removed.accepted)
        compare(removed.document.activeProjectId, "")
        compare(removed.document.projects.length, 1)
        verify(!Library.remove(document, "missing").accepted)
    }
}
