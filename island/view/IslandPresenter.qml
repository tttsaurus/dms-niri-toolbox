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
    property var retainedCompactContentLoader: null
    property bool suppressSceneOpacityAnimation: false
    property int sceneTransitionDuration: 210
    property int sceneTransitionCleanupSlack: 24
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
        root.maximumWidth
    )
    readonly property real requestedHeight: root.saneDimension(
        root.loadedContent?.requestedHeight,
        root.compactHeight,
        root.maximumHeight
    )
    readonly property real targetWidth: root.requestedWidth
    readonly property real targetHeight: root.requestedHeight

    readonly property var contentBaseColorHint: root.loadedContent?.baseColorHint ?? null
    readonly property var contentGlowColorHint: root.loadedContent?.glowColorHint ?? null
    readonly property var contentEdgeColorHint: root.loadedContent?.edgeColorHint ?? null

    readonly property bool contentWantsSplit: root.loadedContent?.wantsSplit === true
    readonly property real contentSplitPercentage: {
        const value = Number(root.loadedContent?.splitPercentage ?? 0.5)
        return Number.isFinite(value) ? Math.max(0.01, Math.min(0.99, value)) : 0.5
    }
    readonly property real compactReservationWidth: {
        const contentReservation = Number(root.loadedContent?.requestedReservationWidth)
        if (!Number.isFinite(contentReservation))
            return root.targetWidth

        return Math.max(root.targetWidth, Math.min(root.maximumWidth, contentReservation))
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

    readonly property var liveContentContext: ({
        idleWidth: root.compactWidth,
        compactMaximumWidth: root.effectiveCompactMaximumWidth,
        compactHeight: root.compactHeight,
        maximumWidth: root.maximumWidth,
        radiusDip: shell.targetRadius,
        liveRadiusDip: shell.animatedRadius,
        liveSplitPercentage: shell.animatedSplitPercentage,
        shapeInset: shell.shapeInset,
        splitProgress: shell.animatedSplit
    })

    onCompactReservationWidthChanged: {
        if (root.controller.mode === "compact")
            root.retainedCompactReservationWidth = root.compactReservationWidth
    }

    width: shell.width
    height: shell.height

    Core.IslandContentRegistry {
        id: registry
    }

    function applyControllerScene() {
        const state = root.controller.sceneState ?? ({})
        const mode = String(state.presentation ?? "compact")
        const context = state.context ?? ({})
        root.switchScene(registry.sceneSourceFor(mode), context)
    }

    function sceneLoaderForSource(source) {
        const sourceText = String(source ?? "")
        const loaders = [sceneLoaderA, sceneLoaderB, sceneLoaderC]

        if (root.retainedCompactContentLoader
                && root.retainedCompactContentLoader !== root.activeContentLoader
                && String(root.retainedCompactContentLoader.source) === sourceText
                && root.retainedCompactContentLoader.status === Loader.Ready)
            return root.retainedCompactContentLoader

        for (let i = 0; i < loaders.length; i++) {
            const loader = loaders[i]
            if (loader === root.activeContentLoader || loader === root.retainedCompactContentLoader)
                continue
            if (String(loader.source) === sourceText && loader.status === Loader.Ready)
                return loader
        }

        for (let i = 0; i < loaders.length; i++) {
            const loader = loaders[i]
            if (loader !== root.activeContentLoader && loader !== root.retainedCompactContentLoader)
                return loader
        }

        return null
    }

    function sceneInitialProperties(sceneContext) {
        return {
            notificationData: root.controller.currentNotification,
            notificationVisible: root.controller.notificationVisible,
            notificationRevision: root.controller.notificationRevision,
            sceneContext: sceneContext ?? ({}),
            widgetStates: root.controller.widgetStates,
            islandContext: root.liveContentContext
        }
    }

    function shouldRetainOutgoingScene(outgoing, incoming) {
        const state = root.controller.sceneState ?? ({})
        if (!outgoing || !incoming || String(state.presentation ?? "compact") !== "peek")
            return false

        const role = String(state.context?.presentationRole ?? "")
        if (role !== "notificationOverflow")
            return false

        return String(outgoing.source) === String(registry.sceneSourceFor("compact"))
            && String(incoming.source) === String(registry.sceneSourceFor("peek"))
    }

    function switchScene(source, sceneContext) {
        const sourceText = String(source ?? "")
        const context = sceneContext ?? ({})
        if (sourceText.length === 0)
            return

        if (root.activeContentLoader && String(root.activeContentLoader.source) === sourceText) {
            if (root.activeContentLoader.item)
                root.activeContentLoader.item.sceneContext = context
            return
        }

        const incoming = root.activeContentLoader ? root.sceneLoaderForSource(sourceText) : sceneLoaderA
        if (!incoming) {
            console.warn("[IslandPresenter] no scene loader available for: ", sourceText)
            return
        }

        incoming.opacity = 0.0

        if (String(incoming.source) === sourceText && incoming.status === Loader.Ready) {
            if (incoming.item)
                incoming.item.sceneContext = context
            root.activateSceneLoader(incoming)
            return
        }

        incoming.setSource(source, root.sceneInitialProperties(context))
        if (incoming.status === Loader.Ready)
            root.activateSceneLoader(incoming)
    }

    function activateSceneLoader(incoming) {
        if (!incoming || incoming.status !== Loader.Ready || root.activeContentLoader === incoming)
            return

        const outgoing = root.activeContentLoader
        const restoringRetainedCompact = incoming === root.retainedCompactContentLoader
            && String(root.controller.sceneState?.presentation ?? "compact") === "compact"
            && String(incoming.source) === String(registry.sceneSourceFor("compact"))

        if (restoringRetainedCompact)
            root.suppressSceneOpacityAnimation = true

        if (root.cleanupContentLoader === incoming) {
            sceneCleanupTimer.stop()
            root.cleanupContentLoader = null
        }

        root.activeContentLoader = incoming

        incoming.opacity = 1.0
        if (outgoing && outgoing.item) {
            outgoing.opacity = 0.0

            if (root.shouldRetainOutgoingScene(outgoing, incoming)) {
                sceneCleanupTimer.stop()
                root.cleanupContentLoader = null
                root.retainedCompactContentLoader = outgoing
            } else {
                root.cleanupContentLoader = outgoing
                sceneCleanupTimer.restart()
            }
        }

        if (restoringRetainedCompact) {
            root.retainedCompactContentLoader = null
            root.suppressSceneOpacityAnimation = false
        }
    }

    Connections {
        target: root.controller

        function onSceneStateChanged() {
            root.applyControllerScene()
        }
    }

    Binding {
        target: sceneLoaderA.item
        property: "notificationData"
        value: root.controller.currentNotification
        when: sceneLoaderA.item !== null
    }

    Binding {
        target: sceneLoaderA.item
        property: "notificationVisible"
        value: root.controller.notificationVisible
        when: sceneLoaderA.item !== null
    }

    Binding {
        target: sceneLoaderA.item
        property: "notificationRevision"
        value: root.controller.notificationRevision
        when: sceneLoaderA.item !== null
    }

    Binding {
        target: sceneLoaderA.item
        property: "widgetStates"
        value: root.controller.widgetStates
        when: sceneLoaderA.item !== null
    }

    Binding {
        target: sceneLoaderA.item
        property: "islandContext"
        value: root.liveContentContext
        when: sceneLoaderA.item !== null
    }

    Binding {
        target: sceneLoaderB.item
        property: "notificationData"
        value: root.controller.currentNotification
        when: sceneLoaderB.item !== null
    }

    Binding {
        target: sceneLoaderB.item
        property: "notificationVisible"
        value: root.controller.notificationVisible
        when: sceneLoaderB.item !== null
    }

    Binding {
        target: sceneLoaderB.item
        property: "notificationRevision"
        value: root.controller.notificationRevision
        when: sceneLoaderB.item !== null
    }

    Binding {
        target: sceneLoaderB.item
        property: "widgetStates"
        value: root.controller.widgetStates
        when: sceneLoaderB.item !== null
    }

    Binding {
        target: sceneLoaderB.item
        property: "islandContext"
        value: root.liveContentContext
        when: sceneLoaderB.item !== null
    }

    Binding {
        target: sceneLoaderC.item
        property: "notificationData"
        value: root.controller.currentNotification
        when: sceneLoaderC.item !== null
    }

    Binding {
        target: sceneLoaderC.item
        property: "notificationVisible"
        value: root.controller.notificationVisible
        when: sceneLoaderC.item !== null
    }

    Binding {
        target: sceneLoaderC.item
        property: "notificationRevision"
        value: root.controller.notificationRevision
        when: sceneLoaderC.item !== null
    }

    Binding {
        target: sceneLoaderC.item
        property: "widgetStates"
        value: root.controller.widgetStates
        when: sceneLoaderC.item !== null
    }

    Binding {
        target: sceneLoaderC.item
        property: "islandContext"
        value: root.liveContentContext
        when: sceneLoaderC.item !== null
    }

    Island.DynamicIsland {
        id: shell

        targetWidth: root.targetWidth
        targetHeight: root.targetHeight
        mode: root.controller.mode

        splitEnabled: root.contentWantsSplit
        splitPercentage: root.contentSplitPercentage

        baseColorHint: root.contentBaseColorHint
        glowColorHint: root.contentGlowColorHint
        edgeColorHint: root.contentEdgeColorHint
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
            enabled: !root.suppressSceneOpacityAnimation

            NumberAnimation {
                duration: root.sceneTransitionDuration
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
            enabled: !root.suppressSceneOpacityAnimation

            NumberAnimation {
                duration: root.sceneTransitionDuration
                easing.type: Easing.OutCubic
            }
        }

        onLoaded: root.activateSceneLoader(sceneLoaderB)
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandPresenter] content load failed: ", source)
        }
    }

    Loader {
        id: sceneLoaderC

        parent: shell.contentItem
        anchors.fill: parent
        z: root.activeContentLoader === sceneLoaderC ? 2 : 1

        asynchronous: false
        opacity: 0.0
        visible: opacity > 0.001
        enabled: root.activeContentLoader === sceneLoaderC

        Behavior on opacity {
            enabled: !root.suppressSceneOpacityAnimation

            NumberAnimation {
                duration: root.sceneTransitionDuration
                easing.type: Easing.OutCubic
            }
        }

        onLoaded: root.activateSceneLoader(sceneLoaderC)
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandPresenter] content load failed: ", source)
        }
    }

    Timer {
        id: sceneCleanupTimer

        interval: root.sceneTransitionDuration + root.sceneTransitionCleanupSlack
        repeat: false
        onTriggered: {
            const loader = root.cleanupContentLoader
            root.cleanupContentLoader = null

            if (loader && loader !== root.activeContentLoader && loader !== root.retainedCompactContentLoader) {
                loader.opacity = 0.0
                loader.source = ""
            }
        }
    }

    Component.onCompleted: root.applyControllerScene()

    Connections {
        target: root.loadedContent
        ignoreUnknownSignals: true

        function onAccessRequested(request) {
            root.controller.requestAccess(request)
        }

        function onSceneRequested(request) {
            root.controller.requestRootPresentation(request)
        }

        function onWidgetStatePatchRequested(widgetId, patch) {
            root.controller.patchWidgetState(widgetId, patch)
        }

        function onDismissRequested() {
            root.controller.dismissScene()
        }
    }
}
