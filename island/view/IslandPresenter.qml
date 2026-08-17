import QtQuick

import ".." as Island
import "../core" as Core

Item {
    id: root

    required property var controller
    required property real compactWidth
    required property real compactHeight

    property real compactMaximumWidth: 360
    property real maximumWidth: 4096
    property real maximumHeight: 4096

    property var activeContentLoader: null
    property var cleanupContentLoader: null
    readonly property var loadedContent: root.activeContentLoader?.item ?? null

    function saneDimension(value, fallback, maximum) {
        const number = Number(value)
        if (!Number.isFinite(number))
            return fallback
        return Math.max(fallback, Math.min(maximum, number))
    }

    readonly property real effectiveCompactMaximumWidth: Math.max(root.compactWidth, Math.min(root.maximumWidth, root.compactMaximumWidth))

    readonly property real requestedWidth: root.saneDimension(
        root.loadedContent?.requestedWidth,
        root.compactWidth,
        root.controller.mode === "compact" ? root.effectiveCompactMaximumWidth : root.maximumWidth
    )
    readonly property real requestedHeight: root.saneDimension(
        root.loadedContent?.requestedHeight,
        root.compactHeight,
        root.maximumHeight
    )
    readonly property real targetWidth: root.requestedWidth
    readonly property real targetHeight: root.requestedHeight

    readonly property bool contentWantsSplit: root.loadedContent?.wantsSplit === true
    readonly property real contentSplitPercentage: {
        const value = Number(root.loadedContent?.splitPercentage ?? 0.5)
        return Number.isFinite(value) ? Math.max(0.01, Math.min(0.99, value)) : 0.5
    }
    readonly property bool animateContentChange: root.loadedContent?.animateContentChange === true
    readonly property string contentAnimation: String(
        root.loadedContent?.contentAnimation ?? "subtle"
    )
    readonly property int contentAnimationRevision: {
        const value = Number(root.loadedContent?.animationRevision ?? 0)
        return Number.isFinite(value) ? Math.floor(value) : 0
    }
    readonly property real compactReservationWidth: {
        const contentReservation = Number(root.loadedContent?.requestedReservationWidth)
        if (!Number.isFinite(contentReservation))
            return root.targetWidth

        return Math.max(root.targetWidth, Math.min(root.effectiveCompactMaximumWidth, contentReservation))
    }

    property real retainedCompactReservationWidth: root.compactWidth

    readonly property real barReservationWidth: {
        switch (root.controller.mode) {
            case "compact":
                return root.compactReservationWidth
            case "peek":
                return Math.max(root.compactWidth, root.retainedCompactReservationWidth)
            case "expanded":
            default:
                return root.compactWidth
        }
    }

    onCompactReservationWidthChanged: {
        if (root.controller.mode === "compact")
            root.retainedCompactReservationWidth = root.compactReservationWidth
    }

    width: shell.width
    height: shell.height

    Core.IslandContentRegistry {
        id: registry
    }

    function contentContext() {
        return {
            mode: root.controller.mode,
            idleWidth: root.compactWidth,
            compactMaximumWidth: root.effectiveCompactMaximumWidth,
            compactHeight: root.compactHeight,
            maximumWidth: root.maximumWidth,
            maximumHeight: root.maximumHeight,
            radiusDip: shell.targetRadius,
            liveRadiusDip: shell.animatedRadius,
            liveSplitPercentage: shell.animatedSplitPercentage,
            shapeInset: shell.shapeInset,
            splitProgress: shell.animatedSplit
        }
    }

    function setOptionalContentProperty(item, name, value) {
        if (!item)
            return

        try {
            if (typeof item[name] !== "undefined")
                item[name] = value
        } catch (error) {
            console.warn(
                "[IslandPresenter] failed to inject content property ",
                name,
                ": ",
                error
            )
        }
    }

    function syncContentItem(item) {
        root.setOptionalContentProperty(item, "notificationData", root.controller.currentNotification)
        root.setOptionalContentProperty(item, "sceneContext", root.controller.sceneContext)
        root.setOptionalContentProperty(item, "widgetStates", root.controller.widgetStates)
        root.setOptionalContentProperty(item, "islandContext", root.contentContext())
    }

    function syncContentInputs() {
        root.syncContentItem(sceneLoaderA.item)
        root.syncContentItem(sceneLoaderB.item)
    }

    function applyControllerScene() {
        const mode = root.controller.mode
        root.switchScene(registry.sceneSourceFor(mode))
        root.syncContentInputs()
    }

    function inactiveContentLoader() {
        return root.activeContentLoader === sceneLoaderA ? sceneLoaderB : sceneLoaderA
    }

    function switchScene(source) {
        const sourceText = String(source ?? "")
        if (sourceText.length === 0)
            return

        if (root.activeContentLoader && String(root.activeContentLoader.source) === sourceText)
            return

        const incoming = root.activeContentLoader ? root.inactiveContentLoader() : sceneLoaderA
        incoming.opacity = 0.0

        if (String(incoming.source) === sourceText && incoming.status === Loader.Ready) {
            root.activateSceneLoader(incoming)
            return
        }

        incoming.source = source
        if (incoming.status === Loader.Ready)
            root.activateSceneLoader(incoming)
    }

    function activateSceneLoader(incoming) {
        if (!incoming || incoming.status !== Loader.Ready || root.activeContentLoader === incoming)
            return

        const outgoing = root.activeContentLoader
        root.activeContentLoader = incoming
        root.syncContentInputs()

        incoming.opacity = 1.0
        if (outgoing && outgoing.item) {
            outgoing.opacity = 0.0
            root.cleanupContentLoader = outgoing
            sceneCleanupTimer.restart()
        }
    }

    onCompactWidthChanged: root.syncContentInputs()
    onCompactHeightChanged: root.syncContentInputs()
    onCompactMaximumWidthChanged: root.syncContentInputs()
    onMaximumWidthChanged: root.syncContentInputs()
    onMaximumHeightChanged: root.syncContentInputs()

    Connections {
        target: root.controller

        function onCurrentNotificationChanged() {
            root.syncContentInputs()
        }

        function onSceneStateChanged() {
            root.applyControllerScene()
        }

        function onWidgetStatesChanged() {
            root.syncContentInputs()
        }
    }

    Island.DynamicIsland {
        id: shell

        targetWidth: root.targetWidth
        targetHeight: root.targetHeight
        mode: root.controller.mode

        splitEnabled: root.contentWantsSplit
        splitPercentage: root.contentSplitPercentage
        contentChangeAnimationEnabled: root.animateContentChange
        contentChangeRevision: root.contentAnimationRevision
        contentChangeAnimation: root.contentAnimation

        onTargetRadiusChanged: root.syncContentInputs()
        onAnimatedRadiusChanged: root.syncContentInputs()
        onAnimatedSplitChanged: root.syncContentInputs()
        onAnimatedSplitPercentageChanged: root.syncContentInputs()
    }

    MouseArea {
        id: islandExpandedDismissArea

        parent: shell.contentItem
        anchors.fill: parent
        z: 0

        visible: root.controller.mode === "expanded"
        enabled: visible

        onClicked: root.controller.dismissScene()
    }

    Loader {
        id: sceneLoaderA

        parent: shell.contentItem
        anchors.fill: parent
        z: root.activeContentLoader === sceneLoaderA ? 2 : 1

        asynchronous: false
        opacity: 0.0
        visible: opacity > 0.001
        enabled: root.activeContentLoader === sceneLoaderA

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        onLoaded: root.activateSceneLoader(sceneLoaderA)
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandPresenter] content load failed: ", source)
        }
    }

    Loader {
        id: sceneLoaderB

        parent: shell.contentItem
        anchors.fill: parent
        z: root.activeContentLoader === sceneLoaderB ? 2 : 1

        asynchronous: false
        opacity: 0.0
        visible: opacity > 0.001
        enabled: root.activeContentLoader === sceneLoaderB

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        onLoaded: root.activateSceneLoader(sceneLoaderB)
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandPresenter] content load failed: ", source)
        }
    }

    Timer {
        id: sceneCleanupTimer

        interval: 200
        repeat: false
        onTriggered: {
            const loader = root.cleanupContentLoader
            root.cleanupContentLoader = null

            if (loader && loader !== root.activeContentLoader) {
                loader.opacity = 0.0
                loader.source = ""
            }
        }
    }

    Component.onCompleted: root.applyControllerScene()

    Connections {
        target: root.loadedContent
        ignoreUnknownSignals: true

        function onSceneRequested(request) {
            root.controller.requestScene(request)
        }

        function onWidgetStatePatchRequested(widgetId, patch) {
            root.controller.patchWidgetState(widgetId, patch)
        }

        function onNotificationDismissRequested() {
            root.controller.dismissCurrentNotification()
        }

        function onDismissRequested() {
            root.controller.dismissScene()
        }
        
        function onClearRequested() {
            root.controller.clear()
        }
    }
}
