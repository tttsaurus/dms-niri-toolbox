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
    readonly property real baseSpacing: 8
    readonly property real idleWidth: Math.max(Number(root.islandContext?.idleWidth ?? 168), 1)
    readonly property real maximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.maximumWidth ?? 4096))
    readonly property real radiusDip: Math.max(Number(root.islandContext?.radiusDip ?? 18), 0)
    readonly property real shapeInset: Math.max(Number(root.islandContext?.shapeInset ?? 5), 0)

    readonly property string exclusiveWidgetId: String(root.sceneContext?.exclusiveWidgetId ?? "")
    readonly property bool musicExclusive: root.exclusiveWidgetId === "musicTrack"
    readonly property bool musicWidgetVisible: Boolean(musicLoader.item?.widgetVisible ?? false)

    property real musicPresentationPresence: root.musicExclusive && root.musicWidgetVisible ? 1.0 : 0.0
    property real entryCompactWidth: root.idleWidth
    property bool entryCompactWidthCaptured: false

    readonly property url notificationSource: root.musicExclusive ? "" : registry.notificationSourceFor(root.notificationData)
    readonly property bool hasNotification:
        !root.musicExclusive
        && root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real clockPreferredWidth: Math.max(Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52), 1) 
    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property real notificationMinimumWidth: Math.max(Number(notificationLoader.item?.minimumWidthHint ?? root.notificationPreferredWidth), 0)
    readonly property real splitProgress: Math.max(0, Math.min(1, Number(root.islandContext?.splitProgress ?? 0)))
    readonly property real liveRadiusDip: Math.max(Number(root.islandContext?.liveRadiusDip ?? root.radiusDip), 0)
    readonly property real liveSplitPercentage: Math.max(0.1, Math.min(0.9, Number(root.islandContext?.liveSplitPercentage ?? root.splitPercentage)))
    readonly property string notificationSide: String(notificationLoader.item?.preferredSideHint ?? "right") === "left" ? "left" : "right"

    readonly property real musicPreferredWidth: Math.max(Number(musicLoader.item?.preferredWidthHint ?? musicLoader.item?.implicitWidth ?? 300), 1)

    readonly property var preferredSplitPlan: root.hasNotification
        ? splitGeometry.findPlanForPiece(
            root.idleWidth,
            root.maximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.notificationPreferredWidth,
            root.notificationSide,
            root.clockPreferredWidth,
            root.piecePadding
        )
        : splitGeometry.failedPlan("no notification", root.idleWidth)

    readonly property var minimumSplitPlan: root.hasNotification && !root.preferredSplitPlan.success
        ? splitGeometry.findPlanForPiece(
            root.idleWidth,
            root.maximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.notificationMinimumWidth,
            root.notificationSide,
            root.clockPreferredWidth,
            root.piecePadding
        )
        : root.preferredSplitPlan

    readonly property var splitPlan: root.preferredSplitPlan.success ? root.preferredSplitPlan : root.minimumSplitPlan
    readonly property bool wantsSplit: !root.musicExclusive && root.hasNotification && root.splitPlan.success
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

    readonly property real normalNaturalWidth: root.clockPreferredWidth + (root.hasNotification ? root.baseSpacing + root.notificationPreferredWidth : 0)
    readonly property real normalWidth: root.wantsSplit ? root.splitPlan.islandWidth : Math.min(root.maximumWidth, Math.max(root.idleWidth, root.normalNaturalWidth + root.contentPadding * 2))
    readonly property real normalStartOffset: Math.max(root.contentPadding, (root.width - root.normalNaturalWidth) / 2)
    readonly property real requestedWidth: root.musicExclusive ? Math.min(root.maximumWidth, Math.max(root.entryCompactWidth, root.musicPreferredWidth + root.contentPadding * 2)) : root.normalWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)

    readonly property bool animateContentChange: true
    readonly property string contentAnimation: root.hasNotification ? String(notificationLoader.item?.animationHint ?? "subtle") : "subtle"
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0

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

    function widgetStateFor(widgetId) {
        const id = String(widgetId ?? "")
        return id.length > 0 && root.widgetStates ? (root.widgetStates[id] ?? ({})) : ({})
    }

    function leaveExclusiveMusicPeek() {
        root.sceneRequested({
            presentation: "compact",
            context: {},
            notificationPolicy: "resume"
        })
    }

    function syncWidgetInputs() {
        if (clockLoader.item) {
            clockLoader.item.presentation = "peek"
            clockLoader.item.widgetState = root.widgetStateFor("clock")
        }

        if (musicLoader.item) {
            musicLoader.item.presentation = "peek"
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
        x: root.wantsSplit || root.splitProgress > 0 ? root.liveLayout.otherContentStartOffset : root.normalStartOffset
        y: 0
        width: root.wantsSplit || root.splitProgress > 0 ? root.liveLayout.otherContentWidth : root.clockPreferredWidth
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
        readonly property bool usesLiveSplit: root.wantsSplit || root.splitProgress > 0
        opacity: !root._displayNotificationData ? 0.0 : usesLiveSplit ? root.splitProgress : root.hasNotification ? 1.0 : 0.0
        x: usesLiveSplit ? root.liveLayout.pieceContentStartOffset : root.normalStartOffset + root.clockPreferredWidth + root.baseSpacing
        y: 0
        width: usesLiveSplit ? root.liveLayout.pieceContentWidth : Math.min(root.notificationPreferredWidth, Math.max(root.width - x - root.contentPadding, 0))
        height: root.height

        onLoaded: item.notificationData = root._displayNotificationData
    }

    property url _displayNotificationSource: ""
    property var _displayNotificationData: null

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

        opacity: root.musicPresentationPresence
        scale: 0.94 + root.musicPresentationPresence * 0.06
        enabled: root.musicWidgetVisible
        anchors.centerIn: parent
        width: Math.min(root.musicPreferredWidth, Math.max(root.width - root.contentPadding * 2, 0))
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

    onMusicWidgetVisibleChanged: {
        if (root.musicExclusive && !root.musicWidgetVisible)
            root.leaveExclusiveMusicPeek()
    }

    onWidgetStatesChanged: root.syncWidgetInputs()

    Connections {
        target: musicLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            root.leaveExclusiveMusicPeek()
        }

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested("musicTrack", patch)
        }
    }
}