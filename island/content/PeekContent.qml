import QtQuick

import "../core" as Core

Item {
    id: root

    property var eventData: null
    property var controller: null
    property var islandContext: null

    signal presentationRequested(string presentation)
    signal eventRequested(var event)
    signal clearRequested()

    readonly property real piecePadding: 7
    readonly property real idleWidth: Math.max(Number(root.islandContext?.idleWidth ?? 168), 1)
    readonly property real maximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.maximumWidth ?? 4096))
    readonly property real radiusDip: Math.max(Number(root.islandContext?.radiusDip ?? 18), 0)
    readonly property real shapeInset: Math.max(Number(root.islandContext?.shapeInset ?? 5), 0)

    readonly property url notificationSource: registry.notificationSourceFor(root.eventData)
    readonly property bool hasNotification: String(root.notificationSource).length > 0 && notificationLoader.status === Loader.Ready

    readonly property real clockNaturalWidth: Math.max(Number(clockLoader.item?.requestedWidth ?? clockLoader.item?.implicitWidth ?? 52), 1)
    readonly property real notificationNaturalWidth: Math.max(Number(notificationLoader.item?.requestedWidth ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property string notificationSide: String(notificationLoader.item?.preferredSide ?? "right") === "left" ? "left" : "right"

    readonly property var splitPlan: root.hasNotification
        ? splitGeometry.findPlanForPiece(
            root.idleWidth,
            root.maximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.notificationNaturalWidth,
            root.notificationSide,
            root.clockNaturalWidth,
            root.piecePadding
        )
        : splitGeometry.failedPlan("no notification", root.idleWidth)

    readonly property bool wantsSplit: root.hasNotification && root.splitPlan.success
    readonly property real splitPercentage: root.wantsSplit ? root.splitPlan.percentage : 0.5

    readonly property real fallbackWidth: Math.min(root.maximumWidth, Math.max(root.idleWidth, root.clockNaturalWidth + root.notificationNaturalWidth + root.piecePadding * 5))

    readonly property real requestedWidth: root.wantsSplit ? root.splitPlan.islandWidth : root.fallbackWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)

    readonly property bool animateContentChange: root.hasNotification
    readonly property string contentAnimation: "subtle"
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0

    Core.IslandContentRegistry {
        id: registry
    }

    Core.IslandSplitGeometry {
        id: splitGeometry
    }

    Loader {
        id: clockLoader

        source: Qt.resolvedUrl("widgets/ClockContent.qml")
        asynchronous: false

        x: root.wantsSplit ? root.splitPlan.otherContentStartOffset : root.piecePadding * 2
        y: 0
        width: root.wantsSplit ? root.splitPlan.otherContentWidth : root.clockNaturalWidth
        height: root.height

        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutQuart
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutQuart
            }
        }
    }

    Loader {
        id: notificationLoader

        source: root.notificationSource
        asynchronous: false

        visible: root.hasNotification
        opacity: visible ? 1.0 : 0.0

        x: root.wantsSplit ? root.splitPlan.pieceContentStartOffset : clockLoader.x + clockLoader.width + root.piecePadding * 2
        y: 0
        width: root.wantsSplit ? root.splitPlan.pieceContentWidth : Math.max(root.width - x - root.piecePadding * 2, 0)
        height: root.height

        onLoaded: {
            if (typeof item.eventData !== "undefined")
                item.eventData = root.eventData
            if (typeof item.controller !== "undefined")
                item.controller = root.controller

            root._animationRevision++
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    onEventDataChanged: {
        if (notificationLoader.item && typeof notificationLoader.item.eventData !== "undefined")
            notificationLoader.item.eventData = root.eventData
    }

    onControllerChanged: {
        if (notificationLoader.item && typeof notificationLoader.item.controller !== "undefined")
            notificationLoader.item.controller = root.controller
    }

    Connections {
        target: notificationLoader.item
        ignoreUnknownSignals: true

        function onPresentationRequested(presentation) {
            root.presentationRequested(presentation)
        }

        function onEventRequested(event) {
            root.eventRequested(event)
        }
        
        function onClearRequested() {
            root.clearRequested()
        }
    }
}
