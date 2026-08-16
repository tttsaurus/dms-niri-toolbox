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
    readonly property real contentPadding: 10
    readonly property real baseSpacing: 6
    readonly property real idleWidth: Math.max(Number(root.islandContext?.idleWidth ?? 168), 1)
    readonly property real compactMaximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.compactMaximumWidth ?? root.idleWidth))
    readonly property real maximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.maximumWidth ?? 4096))
    readonly property real radiusDip: Math.max(Number(root.islandContext?.radiusDip ?? 18), 0)
    readonly property real compactRadiusDip: Math.max(Number(root.sceneContext?.compactRadiusDip ?? root.radiusDip), 0)
    readonly property real shapeInset: Math.max(Number(root.islandContext?.shapeInset ?? 5), 0)

    readonly property string presentationRole: String(root.sceneContext?.presentationRole ?? "")
    readonly property string exclusiveWidgetId: String(root.sceneContext?.exclusiveWidgetId ?? "")
    readonly property bool musicExclusive: root.exclusiveWidgetId === "musicTrack"
    readonly property bool musicWidgetVisible: Boolean(musicLoader.item?.widgetVisible ?? false)

    property real musicPresentationPresence: root.musicExclusive && root.musicWidgetVisible ? 1.0 : 0.0
    property real entryCompactWidth: root.idleWidth
    property bool entryCompactWidthCaptured: false

    readonly property url notificationSource: root.musicExclusive ? "" : registry.notificationSourceFor(root.notificationData)
    readonly property bool notificationReady:
        !root.musicExclusive
        && root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real clockPreferredWidth: Math.max(Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52), 1)
    readonly property real musicPreferredWidth: Math.max(Number(musicLoader.item?.preferredWidthHint ?? musicLoader.item?.implicitWidth ?? 104), 1)
    readonly property real baseNaturalWidth: root.clockPreferredWidth + (root.musicWidgetVisible ? root.baseSpacing + root.musicPreferredWidth : 0)

    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property string notificationSide: String(notificationLoader.item?.preferredSideHint ?? "right") === "left" ? "left" : "right"

    readonly property real splitProgress: Math.max(0, Math.min(1, Number(root.islandContext?.splitProgress ?? 0)))
    readonly property real liveRadiusDip: Math.max(Number(root.islandContext?.liveRadiusDip ?? root.radiusDip), 0)
    readonly property real liveSplitPercentage: Math.max(0.1, Math.min(0.9, Number(root.islandContext?.liveSplitPercentage ?? root.splitPercentage)))

    readonly property var peekSplitPlan: root.notificationReady
        ? splitGeometry.findClampedPlanForPiece(
            root.idleWidth,
            root.maximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.notificationPreferredWidth,
            root.notificationSide,
            root.baseNaturalWidth,
            root.piecePadding
        )
        : splitGeometry.failedPlan("no notification", root.idleWidth)

    readonly property var compactCandidatePlan: root.notificationReady
        ? splitGeometry.findPlanForPiece(
            root.idleWidth,
            root.compactMaximumWidth,
            root.compactRadiusDip,
            root.shapeInset,
            root.notificationPreferredWidth,
            root.notificationSide,
            root.baseNaturalWidth,
            root.piecePadding
        )
        : splitGeometry.failedPlan("no notification", root.idleWidth)

    readonly property var splitPlan: root._displaySplitPlan ?? splitGeometry.failedPlan("no display split", root.idleWidth)
    readonly property bool wantsSplit: !root.musicExclusive && root.notificationData !== null && root.splitPlan.success
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

    readonly property real baseWidth: Math.min(root.maximumWidth, Math.max(root.idleWidth, root.baseNaturalWidth + root.contentPadding * 2))
    readonly property real normalWidth: root.splitPlan.success && (root.notificationReady || root.splitProgress > 0.001) ? root.splitPlan.islandWidth : root.baseWidth
    readonly property real baseStartOffset: root.wantsSplit || root.splitProgress > 0.001 
        ? root.liveLayout.otherContentStartOffset + Math.max((root.liveLayout.otherContentWidth - (root.musicExclusive ? root.clockPreferredWidth : root.baseNaturalWidth)) / 2, 0) 
        : Math.max(root.contentPadding, (root.width - root.baseNaturalWidth) / 2)
    readonly property real requestedWidth: root.musicExclusive
        ? Math.min(root.maximumWidth, Math.max(root.entryCompactWidth, root.musicPreferredWidth + root.contentPadding * 2))
        : root.normalWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)

    readonly property bool animateContentChange: true
    readonly property string contentAnimation: root.notificationReady ? String(notificationLoader.item?.animationHint ?? "subtle") : "subtle"
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0
    property url _displayNotificationSource: ""
    property var _displayNotificationData: null
    property var _displaySplitPlan: null

    Behavior on musicPresentationPresence {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Core.IslandContentRegistry {
        id: registry
    }

    Core.IslandSplitGeometry {
        id: splitGeometry
    }

    function captureEntryCompactWidth() {
        if (root.entryCompactWidthCaptured || root.width <= 0)
            return

        root.entryCompactWidth = Math.max(root.idleWidth, root.width)
        root.entryCompactWidthCaptured = true
    }

    function enterExclusiveMusicPeek() {
        root.sceneRequested({
            presentation: "peek",
            context: {
                exclusiveWidgetId: "musicTrack"
            },
            notificationPolicy: "suspend"
        })
    }

    function leaveExclusiveMusicPeek() {
        root.sceneRequested({
            presentation: "compact",
            context: {},
            notificationPolicy: "resume"
        })
    }

    function reconcileNotificationPresentation() {
        if (root.musicExclusive)
            return

        if (root.notificationReady) {
            if (!root.peekSplitPlan.success) {
                console.warn("[PeekContent] unable to preserve the companion piece within maximumWidth")
                return
            }

            root._displaySplitPlan = root.peekSplitPlan

            if (root.presentationRole === "notificationOverflow" && root.compactCandidatePlan.success) {
                root.sceneRequested({
                    presentation: "compact",
                    context: {},
                    notificationPolicy: "keep"
                })
            }
            return
        }

        if (root.presentationRole === "notificationOverflow"
                && !root.notificationData
                && root.splitProgress <= 0.001) {

            root.sceneRequested({
                presentation: "compact",
                context: {},
                notificationPolicy: "keep"
            })
        }
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
            musicLoader.item.presentation = root.musicExclusive ? "peek" : "compact"
            musicLoader.item.widgetState = root.widgetStateFor("musicTrack")
            musicLoader.item.hostInset = root.shapeInset
        }
    }

    Loader {
        id: clockLoader

        source: registry.widgetSourceFor("clock")
        asynchronous: false

        visible: opacity > 0.001
        opacity: root.musicExclusive ? 0.0 : 1.0
        x: root.baseStartOffset
        y: 0
        width: root.clockPreferredWidth
        height: root.height

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        onLoaded: root.syncWidgetInputs()
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

    MouseArea {
        anchors.fill: parent
        visible: root.musicExclusive && root.musicWidgetVisible
        enabled: visible
        cursorShape: Qt.PointingHandCursor

        onClicked: root.leaveExclusiveMusicPeek()
    }

    Loader {
        id: musicLoader

        source: registry.widgetSourceFor("musicTrack")
        asynchronous: false

        opacity: root.musicExclusive ? root.musicPresentationPresence : (root.musicWidgetVisible ? 1.0 : 0.0)
        scale: root.musicExclusive ? 0.94 + root.musicPresentationPresence * 0.06 : 1.0
        enabled: root.musicWidgetVisible
        x: root.musicExclusive ? (root.width - width) / 2 : root.baseStartOffset + root.clockPreferredWidth + (root.musicWidgetVisible ? root.baseSpacing : 0)
        width: root.musicExclusive ? Math.min(root.musicPreferredWidth, Math.max(root.width - root.contentPadding * 2, 0)) : (root.musicWidgetVisible ? root.musicPreferredWidth : 0)
        height: root.height

        onLoaded: {
            root.syncWidgetInputs()
            root._animationRevision++

            if (root.musicExclusive && !Boolean(item?.widgetVisible ?? false))
                Qt.callLater(root.leaveExclusiveMusicPeek)
        }
    }

    onWidthChanged: root.captureEntryCompactWidth()
    Component.onCompleted: root.captureEntryCompactWidth()

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

    onPeekSplitPlanChanged: Qt.callLater(root.reconcileNotificationPresentation)
    onCompactCandidatePlanChanged: Qt.callLater(root.reconcileNotificationPresentation)
    onSceneContextChanged: root.syncWidgetInputs()

    onSplitProgressChanged: {
        Qt.callLater(root.reconcileNotificationPresentation)

        if (root.splitProgress <= 0.001 && !root.notificationData)
            root.clearRetainedNotification()
    }

    onMusicWidgetVisibleChanged: {
        if (root.musicExclusive && !root.musicWidgetVisible)
            root.leaveExclusiveMusicPeek()
    }

    onWidgetStatesChanged: root.syncWidgetInputs()

    Connections {
        target: musicLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            if (root.musicExclusive)
                root.leaveExclusiveMusicPeek()
            else
                root.enterExclusiveMusicPeek()
        }

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested("musicTrack", patch)
        }
    }
}
