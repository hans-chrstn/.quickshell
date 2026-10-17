import QtQuick
import qs.components.menus
import qs.services.wallpaper.projects

Item {
    id: root

    property var review: null
    property bool confirmationPending: false
    signal dismissed

    function openFor(trackId, sourceItem, localX, localY) {
        if (confirmation.visible || confirmationPending)
            return false;
        review = WallpaperTimelineService.trackRemovalReview(trackId);
        if (!review)
            return false;
        return menu.openFor(sourceItem, localX, localY);
    }

    function requestRemoval(trackId) {
        if (confirmation.visible || confirmationPending)
            return false;
        review = WallpaperTimelineService.trackRemovalReview(trackId);
        if (!review)
            return false;
        if (review.clipCount > 0) {
            confirmation.open();
            return true;
        }
        const removed = WallpaperTimelineService.removeTrack(review.trackId, review);
        if (removed)
            dismissed();
        return removed;
    }

    function presentConfirmation() {
        if (!confirmationPending || menu.visible)
            return;
        confirmationPending = false;
        confirmation.open();
    }

    ContextMenu {
        id: menu
        objectName: "trackContextMenu"
        actions: [
            {
                id: "remove-track",
                label: "Remove track",
                destructive: true,
                enabled: root.review !== null
            }
        ]
        onActionTriggered: actionId => {
            if (actionId !== "remove-track" || !root.review)
                return;
            if (root.review.clipCount > 0) {
                root.confirmationPending = true;
                root.presentConfirmation();
            } else
                WallpaperTimelineService.removeTrack(root.review.trackId, root.review);
        }
        onClosed: {
            if (root.confirmationPending)
                root.presentConfirmation();
            else if (!confirmation.visible)
                root.dismissed();
        }
    }

    ConfirmationDialog {
        id: confirmation
        objectName: "trackRemovalConfirmation"
        title: "Remove track?"
        message: root.review ? "“" + root.review.name + "” contains " + root.review.clipCount + (root.review.clipCount === 1 ? " clip." : " clips.") + " Removing the track also removes these clips from the timeline. Imported media and files are kept." : ""
        onAccepted: {
            if (root.review)
                WallpaperTimelineService.removeTrack(root.review.trackId, root.review);
        }
        onClosed: root.dismissed()
    }
}
