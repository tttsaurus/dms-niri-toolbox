import QtQuick

import "../core" as Core

Item {
    id: root

    property var notificationData: null
    property var sceneContext: ({})
    property var widgetStates: ({})
    property var islandContext: null

    signal sceneRequested(var request)
    signal widgetStatePatchRequested(string widgetId, var patch)
    signal notificationDismissRequested()
    signal clearRequested()

    readonly property real piecePadding: 7
    readonly property real contentPadding: 8
    readonly property real baseSpacing: 6
    readonly property real idleWidth: Math.max(Number(root.islandContext?.idleWidth ?? 168), 1)
    readonly property real compactMaximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.compactMaximumWidth ?? root.idleWidth))
    readonly property real radiusDip: Math.max(Number(root.islandContext?.radiusDip ?? 18), 0)
    readonly property real shapeInset: Math.max(Number(root.islandContext?.shapeInset ?? 5), 0)

    readonly property url notificationSource: registry.notificationSourceFor(root.notificationData)
    readonly property bool hasNotification: String(root.notificationSource).length > 0 && notificationLoader.status === Loader.Ready

    readonly property real clockMinimumWidth: Math.max(Number(clockLoader.item?.minimumWidthHint ?? 52), 1)
    readonly property real clockPreferredWidth: Math.max(root.clockMinimumWidth, Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52))
    readonly property real musicMinimumWidth: Math.max(Number(musicLoader.item?.minimumWidthHint ?? 102), 1)
    readonly property real musicPreferredWidth: Math.max(root.musicMinimumWidth, Number(musicLoader.item?.preferredWidthHint ?? musicLoader.item?.implicitWidth ?? 118))
    readonly property real baseNaturalWidth: root.clockPreferredWidth + root.baseSpacing + root.musicPreferredWidth
    readonly property real baseMinimumWidth: root.clockMinimumWidth + root.baseSpacing + root.musicMinimumWidth

    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property real notificationMinimumWidth: Math.max(Number(notificationLoader.item?.minimumWidthHint ?? root.notificationPreferredWidth), 0)
    readonly property string notificationSide: String(notificationLoader.item?.preferredSideHint ?? "right") === "left" ? "left" : "right"

    readonly property real baseIslandWidth: Math.min(root.compactMaximumWidth, Math.max(root.idleWidth, root.baseNaturalWidth + root.contentPadding * 2))

    readonly property var preferredSplitPlan: root.hasNotification
        ? splitGeometry.findPlanForPiece(
            root.baseIslandWidth,
            root.compactMaximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.notificationPreferredWidth,
            root.notificationSide,
            root.baseNaturalWidth,
            root.piecePadding
        )
        : splitGeometry.failedPlan("no notification", root.baseIslandWidth)

    readonly property var minimumSplitPlan: root.hasNotification && !root.preferredSplitPlan.success
        ? splitGeometry.findPlanForPiece(
            root.baseIslandWidth,
            root.compactMaximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.notificationMinimumWidth,
            root.notificationSide,
            root.baseMinimumWidth,
            root.piecePadding
        )
        : root.preferredSplitPlan

    readonly property var splitPlan: root.preferredSplitPlan.success? root.preferredSplitPlan : root.minimumSplitPlan
    readonly property bool wantsSplit: root.hasNotification && root.splitPlan.success
    readonly property real splitPercentage: root.wantsSplit ? root.splitPlan.percentage : 0.5
    readonly property real baseAvailableWidth: root.wantsSplit ? root.splitPlan.otherContentWidth : root.baseNaturalWidth
    readonly property real clockAssignedWidth: Math.min(root.clockPreferredWidth, Math.max(root.clockMinimumWidth, root.baseAvailableWidth - root.baseSpacing - root.musicMinimumWidth))
    readonly property real musicAssignedWidth: Math.min(root.musicPreferredWidth, Math.max(root.musicMinimumWidth, root.baseAvailableWidth - root.baseSpacing - root.clockAssignedWidth))
    readonly property real requestedWidth: root.wantsSplit ? root.splitPlan.islandWidth : root.baseIslandWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)
    readonly property real requestedReservationWidth: root.requestedWidth

    readonly property bool animateContentChange: root.hasNotification
    readonly property string contentAnimation: String(notificationLoader.item?.animationHint ?? "subtle")
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0

    Core.IslandContentRegistry {
        id: registry
    }

    Core.IslandSplitGeometry {
        id: splitGeometry
    }

    function widgetStateFor(widgetId) {
        const id = String(widgetId ?? "")
        return id.length > 0 && root.widgetStates ? (root.widgetStates[id] ?? ({})) : ({})
    }

    function syncWidgetInputs() {
        if (clockLoader.item) {
            clockLoader.item.presentation = "compact"
            clockLoader.item.widgetState = root.widgetStateFor("clock")
        }

        if (musicLoader.item) {
            musicLoader.item.presentation = "compact"
            musicLoader.item.widgetState = root.widgetStateFor("musicTrack")
        }
    }

    Item {
        id: basePiece

        x: root.wantsSplit ? root.splitPlan.otherContentStartOffset : (root.width - width) / 2
        y: 0
        width: root.wantsSplit ? root.splitPlan.otherContentWidth : root.baseNaturalWidth
        height: root.height

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuart
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuart
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: root.baseSpacing

            Loader {
                id: clockLoader

                width: root.clockAssignedWidth
                height: basePiece.height
                source: registry.widgetSourceFor("clock")
                asynchronous: false

                onLoaded: root.syncWidgetInputs()
            }

            Loader {
                id: musicLoader

                width: root.musicAssignedWidth
                height: basePiece.height
                source: registry.widgetSourceFor("musicTrack")
                asynchronous: false

                onLoaded: root.syncWidgetInputs()
            }
        }
    }

    Loader {
        id: notificationLoader

        source: root.notificationSource
        asynchronous: false

        visible: root.hasNotification && root.wantsSplit
        opacity: visible ? 1.0 : 0.0
        x: root.wantsSplit ? root.splitPlan.pieceContentStartOffset : root.width
        y: 0
        width: root.wantsSplit ? root.splitPlan.pieceContentWidth : 0
        height: root.height

        onLoaded: item.notificationData = root.notificationData

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    onNotificationDataChanged: {
        if (notificationLoader.item)
            notificationLoader.item.notificationData = root.notificationData

        if (root.notificationData)
            root._animationRevision++
    }

    onWidgetStatesChanged: root.syncWidgetInputs()

    Connections {
        target: musicLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            root.sceneRequested({
                presentation: "peek",
                context: {
                    exclusiveWidgetId: "musicTrack"
                },
                notificationPolicy: "suspend"
            })
        }

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested("musicTrack", patch)
        }
    }
}