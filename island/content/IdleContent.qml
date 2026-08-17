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
    signal dismissRequested()
    signal clearRequested()

    readonly property real piecePadding: 7
    readonly property real contentPadding: 8
    readonly property real baseSpacing: 6
    readonly property real idleWidth: Math.max(Number(root.islandContext?.idleWidth ?? 168), 1)
    readonly property real compactMaximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.compactMaximumWidth ?? root.idleWidth))
    readonly property real radiusDip: Math.max(Number(root.islandContext?.radiusDip ?? 18), 0)
    readonly property real shapeInset: Math.max(Number(root.islandContext?.shapeInset ?? 5), 0)

    readonly property url notificationSource: registry.notificationSourceFor(root.notificationData)
    readonly property bool notificationReady:
        root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real clockPreferredWidth: Math.max(Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52), 1)
    readonly property bool musicWidgetVisible: Boolean(musicLoader.item?.widgetVisible ?? false)
    readonly property real rawMusicPreferredWidth: Math.max(Number(musicLoader.item?.preferredWidthHint ?? musicLoader.item?.implicitWidth ?? 104), 1)
    readonly property real baseNaturalWidth: root.clockPreferredWidth + (root.musicWidgetVisible ? root.baseSpacing + root.rawMusicPreferredWidth : 0)

    property real musicLayoutPresence: root.musicWidgetVisible ? 1.0 : 0.0

    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property string notificationSide: String(notificationLoader.item?.preferredSideHint ?? "right") === "left" ? "left" : "right"

    readonly property real splitProgress: Math.max(0, Math.min(1, Number(root.islandContext?.splitProgress ?? 0)))
    readonly property real liveRadiusDip: Math.max(Number(root.islandContext?.liveRadiusDip ?? root.radiusDip), 0)
    readonly property real liveSplitPercentage: Math.max(0.01, Math.min(0.99, Number(root.islandContext?.liveSplitPercentage ?? root.splitPercentage)))

    readonly property real baseIslandWidth: Math.min(root.compactMaximumWidth, Math.max(root.idleWidth, root.baseNaturalWidth + root.contentPadding * 2))
    readonly property var compactSplitPlan: root.notificationReady
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

    readonly property var splitPlan: root._displaySplitPlan ?? splitGeometry.failedPlan("no display split", root.baseIslandWidth)
    readonly property bool wantsSplit: root.notificationData !== null && root.splitPlan.success
    readonly property real splitPercentage: root.splitPlan.success ? root.splitPlan.percentage : 0.5
    readonly property var liveLayout: splitGeometry.layoutForSplitProgress(
        root.width,
        root.liveRadiusDip,
        root.shapeInset,
        root.liveSplitPercentage,
        root.splitProgress,
        String(root.splitPlan?.side ?? root.notificationSide),
        root.piecePadding
    )

    readonly property real requestedWidth: root.splitPlan.success && (root.notificationReady || root.splitProgress > 0.001) ? root.splitPlan.islandWidth : root.baseIslandWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)
    readonly property real requestedReservationWidth: root.requestedWidth

    readonly property bool animateContentChange: root.notificationReady
    readonly property string contentAnimation: String(notificationLoader.item?.animationHint ?? "subtle")
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0
    property url _displayNotificationSource: ""
    property var _displayNotificationData: null
    property var _displaySplitPlan: null

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

    function reconcileNotificationPresentation() {
        if (!root.notificationReady)
            return

        if (root.compactSplitPlan.success) {
            root._displaySplitPlan = root.compactSplitPlan
            return
        }

        root.sceneRequested({
            presentation: "peek",
            context: {
                presentationRole: "notificationOverflow",
                compactRadiusDip: root.radiusDip
            },
            notificationPolicy: "keep"
        })
    }

    function clearRetainedNotification() {
        root._displayNotificationSource = ""
        root._displayNotificationData = null
        root._displaySplitPlan = null
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
            musicLoader.item.hostInset = root.shapeInset
        }
    }

    Item {
        id: basePiece

        x: root.wantsSplit || root.splitProgress > 0.001 ? root.liveLayout.otherContentStartOffset : root.contentPadding
        y: 0
        width: root.wantsSplit || root.splitProgress > 0.001 ? root.liveLayout.otherContentWidth : Math.max(root.width - root.contentPadding * 2, 0)
        height: root.height

        Row {
            anchors.centerIn: parent
            spacing: root.baseSpacing * root.musicLayoutPresence

            Loader {
                id: clockLoader

                width: root.clockPreferredWidth
                height: basePiece.height
                source: registry.widgetSourceFor("clock")
                asynchronous: false

                onLoaded: root.syncWidgetInputs()
            }

            Loader {
                id: musicLoader

                width: root.rawMusicPreferredWidth * root.musicLayoutPresence
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
        opacity: root._displayNotificationData && (root.notificationReady || root.notificationData === null) ? root.splitProgress : 0.0
        x: root.liveLayout.pieceContentStartOffset
        y: 0
        width: root.splitPlan.success ? root.splitPlan.pieceContentWidth : 0
        height: root.height

        onLoaded: {
            item.notificationData = root._displayNotificationData
            Qt.callLater(root.reconcileNotificationPresentation)
        }
    }

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
            root.clearRetainedNotification()
        }
    }

    onCompactSplitPlanChanged: Qt.callLater(root.reconcileNotificationPresentation)

    onSplitProgressChanged: {
        if (root.splitProgress <= 0.001 && !root.notificationData)
            root.clearRetainedNotification()
    }

    onWidgetStatesChanged: root.syncWidgetInputs()

    Connections {
        target: musicLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            root.sceneRequested({
                navigation: "push",
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
