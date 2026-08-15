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

    readonly property url notificationSource: root.musicExclusive ? "" : registry.notificationSourceFor(root.notificationData)
    readonly property bool hasNotification: !root.musicExclusive && String(root.notificationSource).length > 0 && notificationLoader.status === Loader.Ready

    readonly property real clockPreferredWidth: Math.max(Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52), 1) 
    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property real notificationMinimumWidth: Math.max(Number(notificationLoader.item?.minimumWidthHint ?? root.notificationPreferredWidth), 0)
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
    readonly property real normalNaturalWidth: root.clockPreferredWidth + (root.hasNotification ? root.baseSpacing + root.notificationPreferredWidth : 0)
    readonly property real normalWidth: root.wantsSplit ? root.splitPlan.islandWidth : Math.min(root.maximumWidth, Math.max(root.idleWidth, root.normalNaturalWidth + root.contentPadding * 2))
    readonly property real normalStartOffset: Math.max(root.contentPadding, (root.width - root.normalNaturalWidth) / 2)
    readonly property real requestedWidth: root.musicExclusive ? Math.min(root.maximumWidth, Math.max(root.idleWidth, root.musicPreferredWidth + root.contentPadding * 2)) : root.normalWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)

    readonly property bool animateContentChange: true
    readonly property string contentAnimation: root.hasNotification ? String(notificationLoader.item?.animationHint ?? "subtle") : "subtle"
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
        }
    }

    Loader {
        id: clockLoader

        visible: !root.musicExclusive
        source: visible ? registry.widgetSourceFor("clock") : ""
        asynchronous: false

        x: root.wantsSplit ? root.splitPlan.otherContentStartOffset : root.normalStartOffset
        y: 0
        width: root.wantsSplit ? root.splitPlan.otherContentWidth : root.clockPreferredWidth
        height: root.height

        onLoaded: root.syncWidgetInputs()
    }

    Loader {
        id: notificationLoader

        source: root.notificationSource
        asynchronous: false

        visible: root.hasNotification
        opacity: visible ? 1.0 : 0.0
        x: root.wantsSplit ? root.splitPlan.pieceContentStartOffset : root.normalStartOffset + root.clockPreferredWidth + root.baseSpacing
        y: 0
        width: root.wantsSplit ? root.splitPlan.pieceContentWidth : Math.min(root.notificationPreferredWidth, Math.max(root.width - x - root.contentPadding, 0))
        height: root.height

        onLoaded: item.notificationData = root.notificationData

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.musicExclusive
        enabled: visible
        cursorShape: Qt.PointingHandCursor

        onClicked: root.leaveExclusiveMusicPeek()
    }

    Loader {
        id: musicLoader

        visible: root.musicExclusive
        source: visible ? registry.widgetSourceFor("musicTrack") : ""
        asynchronous: false

        anchors.centerIn: parent
        width: Math.min(root.musicPreferredWidth, Math.max(root.width - root.contentPadding * 2, 0))
        height: root.height

        onLoaded: {
            root.syncWidgetInputs()
            root._animationRevision++
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
            root.leaveExclusiveMusicPeek()
        }

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested("musicTrack", patch)
        }
    }
}