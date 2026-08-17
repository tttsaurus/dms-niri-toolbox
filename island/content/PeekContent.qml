import QtQuick

import "../core" as Core
import "components" as Content

Item {
    id: root

    property var notificationData: null
    property var sceneContext: ({})
    property var widgetStates: ({})
    property var islandContext: null

    signal accessRequested(var request)
    signal sceneRequested(var request)
    signal widgetStatePatchRequested(string widgetId, var patch)
    signal notificationDismissRequested()
    signal dismissRequested()
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
    readonly property string primaryWidgetId: String(root.sceneContext?.widgetId ?? root.sceneContext?.exclusiveWidgetId ?? "")
    readonly property bool widgetAccessActive: String(root.sceneContext?.accessKind ?? "") === "widget" && root.primaryWidgetId.length > 0
    readonly property bool ownsNotificationSlot: !root.widgetAccessActive
    readonly property var overflowWidgets: !root.widgetAccessActive && Array.isArray(root.sceneContext?.widgets)
        ? root.sceneContext.widgets
        : []

    readonly property bool primaryWidgetReady: root.widgetAccessActive && root._displayPrimaryWidgetId === root.primaryWidgetId && primaryWidgetHost.widgetReady
    readonly property bool primaryWidgetVisible: root.primaryWidgetReady && primaryWidgetHost.widgetVisible
    readonly property bool primaryWidgetUnavailable:
        root.widgetAccessActive
        && root._displayPrimaryWidgetId === root.primaryWidgetId
        && (primaryWidgetHost.widgetLoadFailed
            || (primaryWidgetHost.widgetReady && !primaryWidgetHost.widgetVisible))

    readonly property var splitCompanionSpec: root.widgetAccessActive 
        ? (root.sceneContext?.splitCompanion ?? registry.companionFor(root.primaryWidgetId, "peek"))
        : null
    readonly property string splitCompanionWidgetId: String(root.splitCompanionSpec?.widgetId ?? "")
    readonly property bool splitCompanionReady:
        root.widgetAccessActive
        && root.splitCompanionWidgetId.length > 0
        && splitCompanionHost.widgetReady
        && splitCompanionHost.widgetVisible
    readonly property string splitCompanionSide: String(root.splitCompanionSpec?.side ?? "right") === "left" ? "left" : "right"
    readonly property real splitCompanionPadding: root.shapeInset
    readonly property real splitCompanionPreferredWidth: Math.max(Number(splitCompanionHost.preferredWidthHint), 1)
    readonly property real splitCompanionSquareContentWidth: Math.max(root.requestedHeight - root.shapeInset * 2 - root.splitCompanionPadding * 2, 1)
    readonly property real splitCompanionRequestedWidth: root.splitCompanionSpec?.square === true
        ? root.splitCompanionSquareContentWidth
        : root.splitCompanionPreferredWidth

    property real accessPresentationProgress: root.widgetAccessActive && root.primaryWidgetVisible ? 1.0 : 0.0
    property bool _focusedBackPending: false
    property int _availabilityEpoch: 0
    property string _displayPrimaryWidgetId: ""

    Behavior on accessPresentationProgress {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    readonly property url notificationSource: root.ownsNotificationSlot
        ? registry.notificationSourceFor(root.notificationData)
        : ""
    readonly property bool notificationReady:
        root.ownsNotificationSlot
        && root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real primaryPreferredWidth: Math.max(Number(primaryWidgetHost.preferredWidthHint), 1)
    readonly property real focusedWidgetWidth: Math.min(root.primaryPreferredWidth, Math.max(root.maximumWidth - root.contentPadding * 2, 0))
    readonly property real baseNaturalWidth: overflowWidgetStrip.naturalWidth

    readonly property real notificationPreferredWidth: Math.max(Number(notificationLoader.item?.preferredWidthHint ?? notificationLoader.item?.implicitWidth ?? 0), 0)
    readonly property string notificationSide: String(notificationLoader.item?.preferredSideHint ?? "right") === "left" ? "left" : "right"

    readonly property real splitProgress: Math.max(0, Math.min(1, Number(root.islandContext?.splitProgress ?? 0)))
    readonly property real liveRadiusDip: Math.max(Number(root.islandContext?.liveRadiusDip ?? root.radiusDip), 0)
    readonly property real liveSplitPercentage: Math.max(0.01, Math.min(0.99, Number(root.islandContext?.liveSplitPercentage ?? root.splitPercentage)))

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

    readonly property var focusedSplitCandidate: root.primaryWidgetReady && root.splitCompanionReady
        ? splitGeometry.findPlanForPiece(
            root.idleWidth,
            root.maximumWidth,
            root.radiusDip,
            root.shapeInset,
            root.splitCompanionRequestedWidth,
            root.splitCompanionSide,
            root.focusedWidgetWidth,
            root.splitCompanionPadding
        )
        : splitGeometry.failedPlan("no focused companion", root.idleWidth)
    readonly property string focusedSplitOwner: String(root.sceneContext?.accessId ?? "") + "|" + root.primaryWidgetId + "|" + root.splitCompanionWidgetId
    readonly property var focusedSplitPlan: root._displayFocusedSplitOwner === root.focusedSplitOwner && root._displayFocusedSplitPlan
        ? root._displayFocusedSplitPlan
        : splitGeometry.failedPlan("no retained focused split", root.idleWidth)

    readonly property var notificationSplitPlan: root._displaySplitPlan ?? splitGeometry.failedPlan("no display split", root.idleWidth)
    readonly property var splitPlan: root.widgetAccessActive ? root.focusedSplitPlan : root.notificationSplitPlan
    readonly property bool wantsSplit: root.widgetAccessActive
        ? root.splitCompanionReady && root.splitPlan.success
        : root.notificationData !== null && root.splitPlan.success
    readonly property real splitPercentage: root.splitPlan.success ? root.splitPlan.percentage : 0.5
    readonly property var liveLayout: splitGeometry.layoutForSplitProgress(
        root.width,
        root.liveRadiusDip,
        root.shapeInset,
        root.liveSplitPercentage,
        root.splitProgress,
        String(root.splitPlan?.side ?? (root.widgetAccessActive ? root.splitCompanionSide : root.notificationSide)),
        root.widgetAccessActive ? root.splitCompanionPadding : root.piecePadding
    )
    readonly property real focusedWidgetViewportWidth: Math.min(root.focusedWidgetWidth, root.liveLayout.otherContentWidth)

    readonly property real baseWidth: Math.min(root.maximumWidth, Math.max(root.idleWidth, root.baseNaturalWidth + root.contentPadding * 2))
    readonly property real normalWidth: root.splitPlan.success && (root.notificationReady || root.splitProgress > 0.001)
        ? root.splitPlan.islandWidth
        : root.baseWidth
    readonly property real baseStartOffset: root.wantsSplit || root.splitProgress > 0.001
        ? root.liveLayout.otherContentStartOffset + Math.max((root.liveLayout.otherContentWidth - root.baseNaturalWidth) / 2, 0)
        : Math.max(root.contentPadding, (root.width - root.baseNaturalWidth) / 2)
    readonly property real requestedWidth: root.widgetAccessActive
        ? (root.focusedSplitPlan.success
            ? root.focusedSplitPlan.islandWidth
            : Math.min(root.maximumWidth, Math.max(root.idleWidth, root.focusedWidgetWidth + root.contentPadding * 2)))
        : root.normalWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)

    readonly property bool animateContentChange: true
    readonly property string contentAnimation: root.notificationReady
        ? String(notificationLoader.item?.animationHint ?? "subtle")
        : "subtle"
    readonly property int animationRevision: root.widgetAccessActive
        ? Number(root.sceneContext?.accessId ?? 0)
        : root._animationRevision

    property int _animationRevision: 0
    property url _displayNotificationSource: ""
    property var _displayNotificationData: null
    property var _displaySplitPlan: null
    property string _displayFocusedSplitOwner: ""
    property var _displayFocusedSplitPlan: null

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

    function currentAccessId() {
        const accessId = Number(root.sceneContext?.accessId ?? 0)
        return Number.isFinite(accessId) ? accessId : 0
    }

    function leaveWidgetAccess(expectedAccessId, expectedEpoch) {
        if (!root.widgetAccessActive || root._focusedBackPending)
            return

        const accessId = Number(expectedAccessId)
        if (Number.isFinite(accessId) && accessId > 0 && root.currentAccessId() !== accessId)
            return

        const epoch = Number(expectedEpoch)
        if (Number.isFinite(epoch) && root._availabilityEpoch !== epoch)
            return

        root._focusedBackPending = true
        root.accessRequested({ navigation: "back" })
    }

    function scheduleUnavailableBack() {
        if (!root.primaryWidgetUnavailable)
            return

        const accessId = root.currentAccessId()
        const epoch = root._availabilityEpoch
        Qt.callLater(function() {
            if (root._availabilityEpoch !== epoch
                    || root.currentAccessId() !== accessId
                    || !root.primaryWidgetUnavailable) return

            root.leaveWidgetAccess(accessId, epoch)
        })
    }

    function reconcileDisplayedPrimaryWidget() {
        if (root.widgetAccessActive) {
            root._displayPrimaryWidgetId = root.primaryWidgetId
            return
        }

        if (root.accessPresentationProgress <= 0.001)
            root._displayPrimaryWidgetId = ""
    }

    function reconcileNotificationPresentation() {
        if (root.widgetAccessActive)
            return

        if (root.notificationReady) {
            if (!root.peekSplitPlan.success) {
                console.warn("[PeekContent] unable to preserve the Notification piece within maximumWidth")
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

    function reconcileFocusedSplitPlan() {
        if (!root.widgetAccessActive)
            return

        if (root._displayFocusedSplitOwner !== root.focusedSplitOwner) {
            root._displayFocusedSplitOwner = root.focusedSplitOwner
            root._displayFocusedSplitPlan = null
        }

        if (root.focusedSplitCandidate.success)
            root._displayFocusedSplitPlan = root.focusedSplitCandidate
    }

    Content.IslandWidgetStrip {
        id: overflowWidgetStrip

        x: root.baseStartOffset
        y: 0
        width: naturalWidth
        height: root.height
        visible: opacity > 0.001
        opacity: 1.0 - root.accessPresentationProgress

        registry: registry
        widgets: root.overflowWidgets
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

    Loader {
        id: notificationLoader

        source: root._displayNotificationSource
        asynchronous: false
        visible: opacity > 0.001
        opacity: root.ownsNotificationSlot && root._displayNotificationData && (root.notificationReady || root.notificationData === null)
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

    MouseArea {
        anchors.fill: parent
        z: 0
        visible: root.widgetAccessActive
        enabled: visible
        cursorShape: Qt.PointingHandCursor

        onClicked: root.leaveWidgetAccess()
    }

    Item {
        id: primaryWidgetViewport

        visible: opacity > 0.001
        opacity: root.accessPresentationProgress
        scale: 0.94 + root.accessPresentationProgress * 0.06
        enabled: root.primaryWidgetVisible
        z: 1
        x: root.liveLayout.otherContentStartOffset + Math.max((root.liveLayout.otherContentWidth - width) / 2, 0)
        width: root.focusedWidgetViewportWidth
        height: root.height
        clip: true

        Content.IslandWidgetHost {
            id: primaryWidgetHost

            x: (parent.width - width) / 2
            y: 0
            width: root.focusedWidgetWidth
            height: parent.height

            registry: registry
            widgetId: root._displayPrimaryWidgetId
            presentation: "peek"
            widgetState: root.widgetStateFor(root._displayPrimaryWidgetId)
            hostInset: root.shapeInset
            hostHeight: root.requestedHeight
            scaleWithVisibility: false

            onStatePatchRequested: function(patch) {
                root.widgetStatePatchRequested(root.primaryWidgetId, patch)
            }
            onAccessRequested: function(request) {
                root.accessRequested(Object.assign({}, request))
            }
        }
    }

    Item {
        id: splitCompanionViewport

        visible: opacity > 0.001
        opacity: root.accessPresentationProgress * root.splitProgress
        scale: 0.86 + root.splitProgress * 0.14
        enabled: root.splitCompanionReady && root.splitProgress > 0.9
        z: 2
        x: root.liveLayout.pieceContentStartOffset
        y: 0
        width: root.splitPlan.success ? root.liveLayout.pieceContentWidth : 0
        height: root.height
        clip: true

        Content.IslandWidgetHost {
            id: splitCompanionHost

            anchors.fill: parent

            registry: registry
            widgetId: root.splitCompanionWidgetId
            presentation: "peek"
            widgetState: root.widgetStateFor(root.splitCompanionWidgetId)
            hostInset: root.shapeInset
            hostHeight: root.requestedHeight
            scaleWithVisibility: false

            onStatePatchRequested: function(patch) {
                root.widgetStatePatchRequested(root.splitCompanionWidgetId, patch)
            }
            onAccessRequested: function(request) {
                root.accessRequested(Object.assign({}, request))
            }
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

    onPeekSplitPlanChanged: Qt.callLater(root.reconcileNotificationPresentation)
    onCompactCandidatePlanChanged: Qt.callLater(root.reconcileNotificationPresentation)
    onFocusedSplitCandidateChanged: root.reconcileFocusedSplitPlan()
    onFocusedSplitOwnerChanged: root.reconcileFocusedSplitPlan()

    onSplitProgressChanged: {
        Qt.callLater(root.reconcileNotificationPresentation)

        if (root.splitProgress <= 0.001 && !root.notificationData)
            root.clearRetainedNotification()

        if (root.splitProgress <= 0.001 && !root.splitCompanionReady) {
            root._displayFocusedSplitOwner = ""
            root._displayFocusedSplitPlan = null
        }
    }

    onOwnsNotificationSlotChanged: {
        if (!root.ownsNotificationSlot)
            root.clearRetainedNotification()
    }

    onWidgetAccessActiveChanged: {
        root._focusedBackPending = false
        root.reconcileDisplayedPrimaryWidget()
        root.reconcileFocusedSplitPlan()
        root.scheduleUnavailableBack()
    }

    onSceneContextChanged: {
        root._availabilityEpoch++
        root._focusedBackPending = false
        root.reconcileDisplayedPrimaryWidget()
        root.reconcileFocusedSplitPlan()
        root.scheduleUnavailableBack()
    }

    Component.onCompleted: {
        root.reconcileDisplayedPrimaryWidget()
        root.reconcileFocusedSplitPlan()
        root.scheduleUnavailableBack()
    }

    onPrimaryWidgetUnavailableChanged: root.scheduleUnavailableBack()
    onAccessPresentationProgressChanged: root.reconcileDisplayedPrimaryWidget()
}
