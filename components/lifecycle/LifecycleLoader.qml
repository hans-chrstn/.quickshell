import QtQuick
import qs.services.lifecycle

Item {
    id: root

    required property string resourceId
    property string owner: ""
    property string restorationSource: ""
    property string classification: "active-only"
    property bool adaptiveEligible: false
    property real estimatedCostUnits: 0
    property real basePriority: 0
    property bool registrationEnabled: true
    property bool requestedActive: true
    property bool usageActive: requestedActive
    property string retentionReason: requestedActive ? "active-request" : ""
    property string evictionReason: requestedActive ? "" : "not-requested"
    property Component sourceComponent: null
    property url source: ""
    readonly property var item: instanceLoader.item
    readonly property int status: instanceLoader.status
    readonly property bool loaded: instanceLoader.item !== null
    property bool registered: false
    property string registeredResourceId: ""
    property bool componentComplete: false

    signal instanceLoaded(var item)
    signal adaptiveEvictionRequested(string reason)

    implicitWidth: instanceLoader.implicitWidth
    implicitHeight: instanceLoader.implicitHeight

    function syncRequested() {
        if (registered)
            LifecycleService.setRequested(registeredResourceId, requestedActive, retentionReason, evictionReason);
    }

    function syncLoaded() {
        if (registered)
            LifecycleService.setLoaded(registeredResourceId, loaded);
    }

    function syncPolicy() {
        if (registered)
            LifecycleService.configureResource(registeredResourceId, adaptiveEligible, estimatedCostUnits, basePriority, restorationSource);
    }

    function syncUsage() {
        if (registered)
            LifecycleService.setActive(registeredResourceId, usageActive);
    }

    function syncInstanceSource() {
        if (!componentComplete)
            return;
        if (String(source).length > 0) {
            instanceLoader.sourceComponent = null;
            instanceLoader.setSource(source);
        } else {
            instanceLoader.source = "";
            instanceLoader.sourceComponent = sourceComponent;
        }
    }

    function registerCurrentResource() {
        if (!registrationEnabled)
            return;
        const nextId = String(resourceId || "").trim();
        registeredResourceId = nextId;
        registered = LifecycleService.registerResource(nextId, owner, classification);
        syncRequested();
        syncUsage();
        syncPolicy();
        Qt.callLater(syncLoaded);
    }

    function rebindResource() {
        if (!componentComplete)
            return;
        if (registered && registrationEnabled && registeredResourceId === resourceId)
            return;
        if (registered)
            LifecycleService.unregisterResource(registeredResourceId, "resource-replaced");
        registered = false;
        if (registrationEnabled)
            registerCurrentResource();
    }

    onResourceIdChanged: rebindResource()
    onRegistrationEnabledChanged: rebindResource()
    onRequestedActiveChanged: syncRequested()
    onUsageActiveChanged: syncUsage()
    onAdaptiveEligibleChanged: syncPolicy()
    onEstimatedCostUnitsChanged: syncPolicy()
    onBasePriorityChanged: syncPolicy()
    onRestorationSourceChanged: syncPolicy()
    onRetentionReasonChanged: syncRequested()
    onEvictionReasonChanged: syncRequested()
    onLoadedChanged: syncLoaded()
    onSourceChanged: syncInstanceSource()
    onSourceComponentChanged: syncInstanceSource()

    Loader {
        id: instanceLoader
        anchors.fill: parent
        active: root.requestedActive
        onLoaded: root.instanceLoaded(item)
    }

    Connections {
        target: LifecycleService
        function onEvictionRequested(resourceId, reason) {
            if (root.registered && root.registeredResourceId === resourceId)
                root.adaptiveEvictionRequested(reason);
        }
    }

    Component.onCompleted: {
        componentComplete = true;
        syncInstanceSource();
        rebindResource();
    }

    Component.onDestruction: {
        if (registered)
            LifecycleService.unregisterResource(registeredResourceId, "owner-destroyed");
    }
}
