import QtQuick
import Quickshell.Services.Notifications
import qs.services

Item {
    id: root

    visible: false
    property var leases: ({})

    function severityFor(urgency) {
        return urgency === NotificationUrgency.Critical ? "error" : "info"
    }

    function requestFor(notification, screenName) {
        return {
            severity: severityFor(notification.urgency),
            title: notification.summary,
            message: notification.body,
            source: notification.appName,
            screenName: screenName,
            dedupeKey: "freedesktop:" + notification.id,
            durationMs: notification.expireTimeout
        }
    }

    function receive(notification) {
        notification.tracked = true
        const screenName = ScreenService.resolve("")
        const noticeId = NotificationService.submit(
            requestFor(notification, screenName))
        if (noticeId.length === 0) {
            notification.dismiss()
            return
        }
        const lease = nativeLease.createObject(root, {
            nativeNotification: notification,
            noticeId: noticeId,
            screenName: screenName
        })
        const next = Object.assign({}, leases)
        next[noticeId] = lease
        leases = next
    }

    function release(noticeId) {
        const next = Object.assign({}, leases)
        delete next[noticeId]
        leases = next
    }

    function closeFromShell(noticeId, reason) {
        const lease = leases[noticeId]
        if (!lease) return
        lease.closingFromShell = true
        if (reason === "expired")
            lease.nativeNotification.expire()
        else
            lease.nativeNotification.dismiss()
    }

    Connections {
        target: NotificationService
        function onClosureRequested(noticeId, reason) {
            root.closeFromShell(noticeId, reason)
        }
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: false
        actionIconsSupported: false
        imageSupported: false
        inlineReplySupported: false

        onNotification: notification => root.receive(notification)
    }

    Component {
        id: nativeLease

        QtObject {
            id: lease

            required property var nativeNotification
            required property string noticeId
            required property string screenName
            property bool closingFromShell: false

            function synchronize() {
                NotificationService.update(noticeId,
                    root.requestFor(nativeNotification, screenName))
            }

            readonly property Connections nativeConnections: Connections {
                target: lease.nativeNotification

                function onSummaryChanged() { lease.synchronize() }
                function onBodyChanged() { lease.synchronize() }
                function onAppNameChanged() { lease.synchronize() }
                function onUrgencyChanged() { lease.synchronize() }
                function onExpireTimeoutChanged() { lease.synchronize() }
                function onClosed(reason) {
                    if (!lease.closingFromShell)
                        NotificationService.remove(lease.noticeId)
                    root.release(lease.noticeId)
                    lease.destroy()
                }
            }
        }
    }
}
