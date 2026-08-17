import QtQuick

Item {
    id: root

    required property var registry
    required property string widgetId

    property string presentation: "compact"
    property var widgetState: ({})
    property real hostInset: 0
    property real hostHeight: root.height
    property bool animateVisibility: true
    property bool scaleWithVisibility: true
    property int visibilityAnimationDuration: 220

    signal activated()
    signal statePatchRequested(var patch)
    signal actionRequested(string action, var payload)
    signal accessRequested(var request)

    readonly property url widgetSource: root.registry.widgetSourceFor(root.widgetId)
    readonly property bool sourceMatches:
        String(root.widgetSource).length > 0
        && String(widgetLoader.source) === String(root.widgetSource)
    readonly property bool widgetReady:
        root.sourceMatches
        && widgetLoader.status === Loader.Ready
        && widgetLoader.item !== null
    readonly property bool widgetVisible:
        root.widgetReady
        && Boolean(widgetLoader.item?.widgetVisible ?? false)

    readonly property real minimumWidthHint: root.widgetReady
        ? root.positiveDimension(widgetLoader.item?.minimumWidthHint, root.preferredWidthHint)
        : 1
    readonly property real preferredWidthHint: root.widgetReady
        ? root.positiveDimension(widgetLoader.item?.preferredWidthHint ?? widgetLoader.item?.implicitWidth, 1)
        : 1
    readonly property real preferredHeightHint: root.widgetReady
        ? root.positiveDimension(widgetLoader.item?.preferredHeightHint ?? widgetLoader.item?.implicitHeight, 36)
        : 36
    readonly property bool interactive: root.widgetReady && Boolean(widgetLoader.item?.interactive ?? false)

    property real visibilityProgress: 0.0
    readonly property real layoutWidth: root.preferredWidthHint * root.visibilityProgress

    property bool _visibilityInitialized: false
    property string _visibilityOwner: ""

    opacity: root.visibilityProgress
    scale: root.scaleWithVisibility ? 0.94 + root.visibilityProgress * 0.06 : 1.0
    visible: root.opacity > 0.001
    enabled: root.widgetVisible && root.visibilityProgress > 0.99

    Behavior on visibilityProgress {
        enabled: root.animateVisibility && root._visibilityInitialized

        NumberAnimation {
            duration: root.visibilityAnimationDuration
            easing.type: Easing.OutCubic
        }
    }

    function positiveDimension(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    function setOptionalWidgetProperty(name, value) {
        const item = widgetLoader.item
        if (!item)
            return

        try {
            if (typeof item[name] !== "undefined")
                item[name] = value
        } catch (error) {
            console.warn(
                "[IslandWidgetHost] failed to inject ",
                name,
                " into ",
                root.widgetId,
                ": ",
                error
            )
        }
    }

    function syncWidgetInputs() {
        if (!widgetLoader.item || !root.sourceMatches)
            return

        root.setOptionalWidgetProperty("presentation", root.presentation)
        root.setOptionalWidgetProperty("widgetState", root.widgetState ?? ({}))
        root.setOptionalWidgetProperty("hostInset", root.hostInset)
        root.setOptionalWidgetProperty("hostHeight", root.hostHeight)
    }

    function reconcileVisibility() {
        const owner = root.widgetId + "|" + String(root.widgetSource)
        if (root._visibilityOwner !== owner) {
            root._visibilityOwner = owner
            root._visibilityInitialized = false
        }

        const target = root.widgetVisible ? 1.0 : 0.0

        if (!root._visibilityInitialized) {
            root.visibilityProgress = target
            root._visibilityInitialized = true
            return
        }

        root.visibilityProgress = target
    }

    Loader {
        id: widgetLoader

        anchors.fill: parent
        source: root.widgetSource
        asynchronous: false

        onLoaded: {
            root.syncWidgetInputs()
            root.reconcileVisibility()
        }

        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandWidgetHost] widget load failed: ", root.widgetId, " ", source)
        }
    }

    onPresentationChanged: root.syncWidgetInputs()
    onWidgetStateChanged: {
        root.syncWidgetInputs()
        Qt.callLater(root.reconcileVisibility)
    }
    onHostInsetChanged: root.syncWidgetInputs()
    onHostHeightChanged: root.syncWidgetInputs()
    onSourceMatchesChanged: {
        if (root.sourceMatches)
            root.syncWidgetInputs()
        root.reconcileVisibility()
    }
    onWidgetVisibleChanged: root.reconcileVisibility()

    Connections {
        target: widgetLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            root.activated()
        }

        function onStatePatchRequested(patch) {
            root.statePatchRequested(patch)
        }

        function onActionRequested(action, payload) {
            root.actionRequested(action, payload)
        }

        function onAccessRequested(request) {
            root.accessRequested(request)
        }
    }

    Component.onCompleted: {
        if (root.widgetReady) {
            root.syncWidgetInputs()
            root.reconcileVisibility()
        }
    }
}
