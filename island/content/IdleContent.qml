import QtQuick

import "../core" as Core
import "components" as Content

Item {
    id: root

    property var notificationData: null
    property var widgetStates: ({})
    property var islandContext: null

    signal accessRequested(var request)
    signal sceneRequested(var request)
    signal widgetStatePatchRequested(string widgetId, var patch)

    readonly property var widgets: [
        "clock",
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
    readonly property bool notificationReady:
        root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real baseNaturalWidth: idleWidgetStrip.naturalWidth
    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property string notificationSide: String(notificationLoader.item?.preferredSideHint ?? "right") === "left" ? "left" : "right"

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

    readonly property real requestedWidth: root.splitPlan.success && (root.notificationReady || root.splitProgress > 0.001)
        ? root.splitPlan.islandWidth
        : root.baseIslandWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)
    readonly property real requestedReservationWidth: root.requestedWidth

    readonly property bool animateContentChange: root.notificationReady
    readonly property string contentAnimation: String(notificationLoader.item?.animationHint ?? "subtle")
    readonly property int animationRevision: root._animationRevision

    property int _animationRevision: 0
    property url _displayNotificationSource: ""
    property var _displayNotificationData: null
    property var _displaySplitPlan: null

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
                compactRadiusDip: root.radiusDip,
                widgets: root.widgets.slice()
            }
        })
    }

    function clearRetainedNotification() {
        root._displayNotificationSource = ""
        root._displayNotificationData = null
        root._displaySplitPlan = null
    }

    Item {
        id: basePiece

        x: root.wantsSplit || root.splitProgress > 0.001
            ? root.liveLayout.otherContentStartOffset
            : root.contentPadding
        y: 0
        width: root.wantsSplit || root.splitProgress > 0.001
            ? root.liveLayout.otherContentWidth
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

    Loader {
        id: notificationLoader

        source: root._displayNotificationSource
        asynchronous: false
        visible: opacity > 0.001
        opacity: root._displayNotificationData && (root.notificationReady || root.notificationData === null)
            ? root.splitProgress
            : 0.0
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
}
