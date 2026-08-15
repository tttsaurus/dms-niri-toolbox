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

    readonly property var loadedContent: contentLoader.item

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
    readonly property real targetHeight: root.controller.mode === "expanded" ? root.requestedHeight : root.compactHeight

    readonly property bool contentWantsSplit: root.loadedContent?.wantsSplit === true
    readonly property real contentSplitPercentage: {
        const value = Number(root.loadedContent?.splitPercentage ?? 0.5)
        return Number.isFinite(value) ? Math.max(0.1, Math.min(0.9, value)) : 0.5
    }

    readonly property bool animateContentChange: root.loadedContent?.animateContentChange === true
    readonly property string contentAnimation: String(root.loadedContent?.contentAnimation ?? "subtle")
    readonly property int contentAnimationRevision: {
        const value = Number(root.loadedContent?.animationRevision ?? 0)
        return root.contentLoadRevision * 100000 + (Number.isFinite(value) ? Math.floor(value) : 0)
    }

    readonly property real barReservationWidth: {
        if (root.controller.mode !== "compact")
            return root.compactWidth

        const contentReservation = Number(root.loadedContent?.requestedReservationWidth)
        if (!Number.isFinite(contentReservation))
            return root.targetWidth

        return Math.max(root.targetWidth, Math.min(root.effectiveCompactMaximumWidth, contentReservation))
    }

    property int contentLoadRevision: 0

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
            shapeInset: shell.shapeInset
        }
    }

    function setOptionalContentProperty(name, value) {
        const item = root.loadedContent
        if (!item)
            return

        try {
            if (typeof item[name] !== "undefined")
                item[name] = value
        } catch (error) {
            console.warn("[IslandPresenter] failed to inject content property ", name, ": ", error)
        }
    }

    function syncContentInputs() {
        root.setOptionalContentProperty("eventData", root.controller.currentEvent)
        root.setOptionalContentProperty("controller", root.controller)
        root.setOptionalContentProperty("islandContext", root.contentContext())
    }

    onCompactWidthChanged: syncContentInputs()
    onCompactHeightChanged: syncContentInputs()
    onCompactMaximumWidthChanged: syncContentInputs()
    onMaximumWidthChanged: syncContentInputs()
    onMaximumHeightChanged: syncContentInputs()

    Connections {
        target: root.controller

        function onCurrentEventChanged() {
            root.syncContentInputs()
        }

        function onModeChanged() {
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
    }

    MouseArea {
        id: islandExpandedDismissArea

        parent: shell.contentItem
        anchors.fill: parent
        z: 0

        visible: root.controller.mode === "expanded"
        enabled: visible

        onClicked: root.controller.clear()
    }

    Loader {
        id: contentLoader

        parent: shell.contentItem
        anchors.fill: parent
        z: 1

        asynchronous: false
        source: registry.sceneSourceFor(root.controller.mode, root.controller.currentEvent)

        onLoaded: {
            root.contentLoadRevision++
            root.syncContentInputs()
        }

        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandPresenter] content load failed: ", source)
        }
    }

    Connections {
        target: root.loadedContent
        ignoreUnknownSignals: true

        function onPresentationRequested(presentation) {
            root.controller.requestPresentation(presentation)
        }

        function onEventRequested(event) {
            root.controller.push(event)
        }

        function onClearRequested() {
            root.controller.clear()
        }
    }
}