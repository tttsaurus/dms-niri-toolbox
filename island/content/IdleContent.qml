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
    readonly property bool hasNotification:
        root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real clockMinimumWidth: Math.max(Number(clockLoader.item?.minimumWidthHint ?? 52), 1)
    readonly property real clockPreferredWidth: Math.max(root.clockMinimumWidth, Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52))
    readonly property bool musicWidgetVisible: Boolean(musicLoader.item?.widgetVisible ?? false)
    readonly property real rawMusicMinimumWidth: Math.max(Number(musicLoader.item?.minimumWidthHint ?? 88), 1)
    readonly property real rawMusicPreferredWidth: Math.max(root.rawMusicMinimumWidth, Number(musicLoader.item?.preferredWidthHint ?? musicLoader.item?.implicitWidth ?? 104))

    property real musicLayoutPresence: root.musicWidgetVisible ? 1.0 : 0.0

    readonly property real effectiveBaseSpacing: root.baseSpacing * root.musicLayoutPresence
    readonly property real musicMinimumWidth: root.rawMusicMinimumWidth * root.musicLayoutPresence
    readonly property real musicPreferredWidth: root.rawMusicPreferredWidth * root.musicLayoutPresence
    readonly property real baseNaturalWidth: root.clockPreferredWidth + root.effectiveBaseSpacing + root.musicPreferredWidth
    readonly property real baseMinimumWidth: root.clockMinimumWidth + root.effectiveBaseSpacing + root.musicMinimumWidth

    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property real splitProgress: Math.max(0, Math.min(1, Number(root.islandContext?.splitProgress ?? 0)))
    readonly property real liveRadiusDip: Math.max(Number(root.islandContext?.liveRadiusDip ?? root.radiusDip), 0)
    readonly property real liveSplitPercentage: Math.max(0.1, Math.min(0.9, Number(root.islandContext?.liveSplitPercentage ?? root.splitPercentage)))
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
    readonly property var liveLayout: splitGeometry.layoutForSplitProgress(
        root.width,
        root.liveRadiusDip,
        root.shapeInset,
        root.liveSplitPercentage,
        root.splitProgress,
        root.notificationSide,
        root.piecePadding
    )

    readonly property real baseAvailableWidth: root.liveLayout.otherContentWidth
    readonly property real baseUsableWidth: Math.max(root.baseAvailableWidth - root.effectiveBaseSpacing, 0)
    readonly property real baseMinimumPayloadWidth: root.clockMinimumWidth + root.musicMinimumWidth
    readonly property real clockAssignedWidth: {
        const preferredPayloadWidth = root.clockPreferredWidth + root.musicPreferredWidth
        if (root.baseUsableWidth >= preferredPayloadWidth)
            return root.clockPreferredWidth

        if (root.baseUsableWidth >= root.baseMinimumPayloadWidth)
            return Math.min(root.clockPreferredWidth, Math.max(root.clockMinimumWidth, root.baseUsableWidth - root.musicMinimumWidth))

        const ratio = root.baseMinimumPayloadWidth > 0 ? root.clockMinimumWidth / root.baseMinimumPayloadWidth : 1.0
        return root.baseUsableWidth * ratio
    }
    readonly property real musicAssignedWidth: {
        if (root.musicLayoutPresence <= 0.001)
            return 0

        const available = Math.max(0, root.baseUsableWidth - root.clockAssignedWidth)
        return Math.min(root.musicPreferredWidth, available)
    }
    readonly property real requestedWidth: root.wantsSplit ? root.splitPlan.islandWidth : root.baseIslandWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)
    readonly property real requestedReservationWidth: root.requestedWidth

    readonly property bool animateContentChange: root.hasNotification
    readonly property string contentAnimation: String(notificationLoader.item?.animationHint ?? "subtle")
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0

    Behavior on musicLayoutPresence {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

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

        x: root.liveLayout.otherContentStartOffset
        y: 0
        width: root.liveLayout.otherContentWidth
        height: root.height

        Row {
            anchors.centerIn: parent
            spacing: root.effectiveBaseSpacing

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
                opacity: root.musicLayoutPresence
                scale: 0.94 + root.musicLayoutPresence * 0.06
                enabled: root.musicWidgetVisible

                onLoaded: root.syncWidgetInputs()
            }
        }
    }

    Loader {
        id: notificationLoader

        source: root._displayNotificationSource
        asynchronous: false

        visible: opacity > 0.001
        opacity: root._displayNotificationData && (root.wantsSplit || root.splitProgress > 0) ? root.splitProgress : 0.0
        x: root.liveLayout.pieceContentStartOffset
        y: 0
        width: root.liveLayout.pieceContentWidth
        height: root.height

        onLoaded: item.notificationData = root._displayNotificationData
    }

    property url _displayNotificationSource: ""
    property var _displayNotificationData: null

    onNotificationDataChanged: {
        if (root.notificationData) {
            const source = registry.notificationSourceFor(root.notificationData)
            if (String(source).length > 0) {
                root._displayNotificationSource = source
                root._displayNotificationData = root.notificationData

                if (notificationLoader.item)
                    notificationLoader.item.notificationData = root.notificationData
            }

            root._animationRevision++
        } else if (root.splitProgress <= 0.001) {
            root._displayNotificationSource = ""
            root._displayNotificationData = null
        }
    }

    onSplitProgressChanged: {
        if (root.splitProgress <= 0.001 && !root.notificationData) {
            root._displayNotificationSource = ""
            root._displayNotificationData = null
        }
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