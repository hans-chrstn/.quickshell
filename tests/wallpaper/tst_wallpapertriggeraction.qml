import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTriggerAction.js" as Action

TestCase {
    name: "WallpaperTriggerAction"

    function test_normalizesSupportedActions() {
        const result = Action.normalizeActions([
            {
                id: "set",
                type: "set-property",
                target: "opacity",
                value: 0.5
            }
        ]);
        verify(result.accepted);
        compare(result.actions[0].target, "opacity");
        compare(result.actions[0].value, 0.5);
    }

    function test_rejectsUnknownAndDuplicateActions() {
        verify(!Action.normalizeActions([
            {
                id: "bad",
                type: "shell"
            }
        ]).accepted);
        verify(!Action.normalizeActions([
            {
                id: "same",
                type: "play-media"
            },
            {
                id: "same",
                type: "set-wallpaper"
            }
        ]).accepted);
    }

    function test_actionChangesRemainImmutable() {
        const original = [
            {
                id: "fade",
                type: "set-property",
                target: "opacity"
            }
        ];
        const added = Action.addAction(original, {
            id: "sound",
            type: "play-media",
            target: "intro"
        });
        verify(added.accepted);
        compare(original.length, 1);
        const updated = Action.updateAction(added.actions, "fade", {
            target: "brightness",
            value: 0.8
        });
        compare(updated.actions[0].target, "brightness");
        const removed = Action.removeAction(updated.actions, "sound");
        compare(removed.actions.length, 1);
    }

    function test_rejectsMalformedCollections() {
        verify(!Action.normalizeActions(null).accepted);
        verify(!Action.normalizeActions(new Array(17).fill({
            id: "x",
            type: "play-media"
        })).accepted);
    }

    function test_rejectsUnknownMutationOperation() {
        const source = [
            {
                id: "action-1",
                type: "set-wallpaper",
                target: "a"
            }
        ];
        const result = Action.changeActions(source, "replace-all", "action-1", {});
        verify(!result.accepted);
        compare(source[0].target, "a");
    }
}
