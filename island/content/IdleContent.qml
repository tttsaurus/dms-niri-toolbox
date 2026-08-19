import QtQuick

import "../core" as Core
import "components" as Content

Item {
    id: root

    property var notificationData: null
    property bool notificationVisible: false
    property int notificationRevision: 0
    property var sceneContext: ({})
    property var widgetStates: ({})
    property var islandContext: null

    signal accessRequested(var request)
    signal sceneRequested(var request)
    signal widgetStatePatchRequested(string widgetId, var patch)

    readonly property var widgets: [
        "clock",
        // "spacer",
        // "test1",
        // "spacer",
        "musicTrack"
    ]

    readonly property real piecePadding: 7
    readonly property real contentPadding: 8
    readonly property real baseSpacing: 6
    readonly property real idleWidth: Math.max(Number(root.islandContext?.idleWidth ?? 168), 1)
    readonly property real compactMaximumWidth: Math.max(root.idleWidth, Number(root.islandContext?.compactMaximumWidth ?? root.idleWidth))
    readonly property real radiusDip: Math.max(Number(root.islandContext?.radiusDip ?? 18), 0)
    readonly property real shapeInset: Math.max(Number(root.islandContext?.shapeInset ?? 5), 0)

    readonly property url notificationSource: registry.notificationSourceFor(root.notificationData)
    readonly property bool notificationReady: notificationHost.notificationReady

    readonly property real baseNaturalWidth: idleWidgetStrip.naturalWidth
    readonly property real notificationPreferredWidth: Math.max(Number(notificationHost.preferredWidthHint), 0)
    readonly property string notificationSide: notificationHost.preferredSideHint

    readonly property real splitProgress: Math.max(0, Math.min(1, Number(root.islandContext?.splitProgress ?? 0)))
    readonly property real liveRadiusDip: Math.max(Number(root.islandContext?.liveRadiusDip ?? root.radiusDip), 0)
    readonly property real liveSplitPercentage: Math.max(0.01, Math.min(0.99, Number(root.islandContext?.liveSplitPercentage ?? root.splitPercentage)))

    readonly property real baseIslandWidth: Math.max(root.idleWidth, root.baseNaturalWidth + root.contentPadding * 2)
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
    readonly property bool notificationPresented:
        root.notificationVisible
        && root.notificationReady
        && root.splitPlan.success
    readonly property bool wantsSplit: root.notificationPresented
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
    readonly property real baseLayoutCorrection:
        (root.shapeInset + root.piecePadding - root.contentPadding)
        * (1.0 - root.splitProgress)

    readonly property real requestedWidth: root.splitPlan.success && (root.notificationPresented || root.splitProgress > 0.001)
        ? root.splitPlan.islandWidth
        : root.baseIslandWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)
    readonly property real requestedReservationWidth: root.requestedWidth

    property var _displaySplitPlan: null

    Core.IslandContentRegistry {
        id: registry
    }

    Core.IslandSplitGeometry {
        id: splitGeometry
    }

    function reconcileNotificationPresentation() {
        if (!root.notificationVisible || !root.notificationReady)
            return

        if (root.compactSplitPlan.success) {
            root._displaySplitPlan = root.compactSplitPlan
            return
        }

        root.sceneRequested({
            presentation: "peek",
            context: {
                presentationRole: "notificationOverflow",
                widgets: root.widgets.slice()
            }
        })
    }

    Item {
        id: basePiece

        x: root.wantsSplit || root.splitProgress > 0.001
            ? root.liveLayout.otherContentStartOffset - root.baseLayoutCorrection
            : root.contentPadding
        y: 0
        width: root.wantsSplit || root.splitProgress > 0.001
            ? root.liveLayout.otherContentWidth + root.baseLayoutCorrection * 2
            : Math.max(root.width - root.contentPadding * 2, 0)
        height: root.height

        Content.IslandWidgetStrip {
            id: idleWidgetStrip

            anchors.centerIn: parent
            width: naturalWidth
            height: parent.height

            registry: registry
            widgets: root.widgets
            widgetStates: root.widgetStates
            presentation: "compact"
            spacing: root.baseSpacing
            hostInset: root.shapeInset
            hostHeight: root.requestedHeight

            onStatePatchRequested: function(widgetId, patch) {
                root.widgetStatePatchRequested(widgetId, patch)
            }
            onAccessRequested: function(request) {
                root.accessRequested(Object.assign({}, request))
            }
        }
    }

    Content.IslandNotificationHost {
        id: notificationHost

        notificationSource: root.notificationSource
        notificationData: root.notificationData
        notificationVisible: root.notificationVisible
        notificationRevision: root.notificationRevision
        splitProgress: root.splitProgress
        x: root.liveLayout.pieceContentStartOffset
        width: root.splitPlan.success ? root.splitPlan.pieceContentWidth : 0
        height: root.height
    }

    onNotificationVisibleChanged: Qt.callLater(root.reconcileNotificationPresentation)
    onNotificationRevisionChanged: {
        root._displaySplitPlan = null
        Qt.callLater(root.reconcileNotificationPresentation)
    }
    onNotificationReadyChanged: Qt.callLater(root.reconcileNotificationPresentation)
    onCompactSplitPlanChanged: Qt.callLater(root.reconcileNotificationPresentation)
}
