import QtQuick

import ".." as Island
import "../core" as Core

Item {
    id: root

    required property var controller
    required property real compactWidth
    required property real compactHeight

    property real maximumWidth: 4096
    property real maximumHeight: 4096

    readonly property var loadedContent: contentLoader.item

    function saneDimension(value, fallback, maximum) {
        const number = Number(value)
        if (!Number.isFinite(number))
            return fallback

        return Math.max(
            fallback,
            Math.min(maximum, number)
        )
    }

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

    readonly property real targetWidth: root.controller.mode === "compact" ? root.compactWidth : root.requestedWidth
    readonly property real targetHeight: root.controller.mode === "expanded" ? root.requestedHeight : root.compactHeight

    width: shell.width
    height: shell.height

    Core.IslandContentRegistry {
        id: registry
    }

    Island.DynamicIsland {
        id: shell

        targetWidth: root.targetWidth
        targetHeight: root.targetHeight
        mode: root.controller.mode
    }

    Loader {
        id: contentLoader

        parent: shell.contentItem
        anchors.fill: parent

        asynchronous: false
        source: registry.sourceFor(root.controller.currentEvent)

        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandPresenter] content load failed: ", source)
        }
    }

    Binding {
        target: contentLoader.item
        property: "eventData"
        value: root.controller.currentEvent
        when: contentLoader.item !== null
    }

    Binding {
        target: contentLoader.item
        property: "controller"
        value: root.controller
        when: contentLoader.item !== null
    }
}
