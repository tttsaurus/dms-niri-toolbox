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
    readonly property bool focusedWidgetActive: root.exclusiveWidgetId.length > 0
    readonly property string primaryWidgetId: root.focusedWidgetActive ? root.exclusiveWidgetId : "musicTrack"
    readonly property url primaryWidgetSource: registry.widgetSourceFor(root.primaryWidgetId)
    readonly property bool primaryWidgetReady:
        String(root.primaryWidgetSource).length > 0
        && String(primaryWidgetLoader.source) === String(root.primaryWidgetSource)
        && primaryWidgetLoader.status === Loader.Ready
    readonly property bool primaryWidgetVisible: root.primaryWidgetReady && Boolean(primaryWidgetLoader.item?.widgetVisible ?? false)

    readonly property var splitCompanionSpec: root.focusedWidgetActive
        ? (root.sceneContext?.splitCompanion ?? registry.peekCompanionFor(root.exclusiveWidgetId))
        : null
    readonly property string splitCompanionWidgetId: String(root.splitCompanionSpec?.widgetId ?? "")
    readonly property url splitCompanionSource: registry.widgetSourceFor(root.splitCompanionWidgetId)
    readonly property bool splitCompanionReady:
        root.focusedWidgetActive
        && root.splitCompanionWidgetId.length > 0
        && String(root.splitCompanionSource).length > 0
        && splitCompanionLoader.status === Loader.Ready
        && Boolean(splitCompanionLoader.item?.widgetVisible ?? false)
    readonly property string splitCompanionSide: String(root.splitCompanionSpec?.side ?? "right") === "left" ? "left" : "right"
    readonly property real splitCompanionPadding: root.shapeInset
    readonly property real splitCompanionPreferredWidth: Math.max(Number(splitCompanionLoader.item?.preferredWidthHint ?? splitCompanionLoader.item?.implicitWidth ?? 16), 1)
    readonly property real splitCompanionSquareContentWidth: Math.max(root.requestedHeight - root.shapeInset * 2 - root.splitCompanionPadding * 2, 1)
    readonly property real splitCompanionRequestedWidth: root.splitCompanionSpec?.square === true
        ? root.splitCompanionSquareContentWidth
        : root.splitCompanionPreferredWidth

    property real focusedPresentationPresence: root.focusedWidgetActive && root.primaryWidgetVisible ? 1.0 : 0.0
    property bool _focusedBackPending: false

    readonly property url notificationSource: root.focusedWidgetActive ? "" : registry.notificationSourceFor(root.notificationData)
    readonly property bool notificationReady:
        !root.focusedWidgetActive
        && root.notificationData !== null
        && String(root.notificationSource).length > 0
        && String(root._displayNotificationSource) === String(root.notificationSource)
        && notificationLoader.status === Loader.Ready

    readonly property real clockPreferredWidth: Math.max(Number(clockLoader.item?.preferredWidthHint ?? clockLoader.item?.implicitWidth ?? 52), 1)
    readonly property real primaryPreferredWidth: Math.max(Number(primaryWidgetLoader.item?.preferredWidthHint ?? primaryWidgetLoader.item?.implicitWidth ?? 104), 1)
    readonly property real focusedWidgetWidth: Math.min(root.primaryPreferredWidth, Math.max(root.maximumWidth - root.contentPadding * 2, 0))
    readonly property real baseNaturalWidth: root.clockPreferredWidth + (root.primaryWidgetVisible ? root.baseSpacing + root.primaryPreferredWidth : 0)

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

    readonly property var focusedSplitPlan: root.splitCompanionReady
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

    readonly property var notificationSplitPlan: root._displaySplitPlan ?? splitGeometry.failedPlan("no display split", root.idleWidth)
    readonly property var splitPlan: root.focusedWidgetActive ? root.focusedSplitPlan : root.notificationSplitPlan
    readonly property bool wantsSplit: root.focusedWidgetActive
        ? root.splitCompanionReady && root.splitPlan.success
        : root.notificationData !== null && root.splitPlan.success
    readonly property real splitPercentage: root.splitPlan.success ? root.splitPlan.percentage : 0.5
    readonly property var liveLayout: splitGeometry.layoutForSplitProgress(
        root.width,
        root.liveRadiusDip,
        root.shapeInset,
        root.liveSplitPercentage,
        root.splitProgress,
        String(root.splitPlan?.side ?? (root.focusedWidgetActive ? root.splitCompanionSide : root.notificationSide)),
        root.focusedWidgetActive ? root.splitCompanionPadding : root.piecePadding
    )
    readonly property real focusedWidgetViewportWidth: Math.min(root.focusedWidgetWidth, root.liveLayout.otherContentWidth)

    readonly property real baseWidth: Math.min(root.maximumWidth, Math.max(root.idleWidth, root.baseNaturalWidth + root.contentPadding * 2))
    readonly property real normalWidth: root.splitPlan.success && (root.notificationReady || root.splitProgress > 0.001) ? root.splitPlan.islandWidth : root.baseWidth
    readonly property real baseStartOffset: root.wantsSplit || root.splitProgress > 0.001 
        ? root.liveLayout.otherContentStartOffset + Math.max((root.liveLayout.otherContentWidth - root.baseNaturalWidth) / 2, 0)
        : Math.max(root.contentPadding, (root.width - root.baseNaturalWidth) / 2)
    readonly property real requestedWidth: root.focusedWidgetActive
        ? (root.focusedSplitPlan.success
            ? root.focusedSplitPlan.islandWidth
            : Math.min(root.maximumWidth, Math.max(root.idleWidth, root.focusedWidgetWidth + root.contentPadding * 2)))
        : root.normalWidth
    readonly property real requestedHeight: Number(root.islandContext?.compactHeight ?? 36)

    readonly property bool animateContentChange: true
    readonly property string contentAnimation: root.notificationReady ? String(notificationLoader.item?.animationHint ?? "subtle") : "subtle"
    readonly property int animationRevision: _animationRevision

    property int _animationRevision: 0
    property url _displayNotificationSource: ""
    property var _displayNotificationData: null
    property var _displaySplitPlan: null

    Behavior on focusedPresentationPresence {
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

    function enterFocusedWidgetPeek(widgetId) {
        const id = String(widgetId ?? "")
        if (id.length === 0)
            return

        root.sceneRequested({
            navigation: "push",
            presentation: "peek",
            context: {
                exclusiveWidgetId: id
            },
            notificationPolicy: "suspend"
        })
    }

    function leaveFocusedWidgetPeek() {
        if (!root.focusedWidgetActive || root._focusedBackPending)
            return

        root._focusedBackPending = true
        root.sceneRequested({ navigation: "back" })
    }

    function reconcileNotificationPresentation() {
        if (root.focusedWidgetActive)
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

        if (primaryWidgetLoader.item) {
            primaryWidgetLoader.item.widgetState = root.widgetStateFor(root.primaryWidgetId)
            if (typeof primaryWidgetLoader.item.hostInset !== "undefined")
                primaryWidgetLoader.item.hostInset = root.shapeInset
            if (typeof primaryWidgetLoader.item.hostHeight !== "undefined")
                primaryWidgetLoader.item.hostHeight = root.requestedHeight
        }

        if (splitCompanionLoader.item) {
            splitCompanionLoader.item.presentation = "peek"
            splitCompanionLoader.item.widgetState = root.widgetStateFor(root.splitCompanionWidgetId)
        }
    }

    Loader {
        id: clockLoader

        source: registry.widgetSourceFor("clock")
        asynchronous: false

        visible: opacity > 0.001
        opacity: root.focusedWidgetActive ? 0.0 : 1.0
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
        z: 0
        visible: root.focusedWidgetActive && root.primaryWidgetVisible
        enabled: visible
        cursorShape: Qt.PointingHandCursor

        onClicked: root.leaveFocusedWidgetPeek()
    }

    Binding {
        target: primaryWidgetLoader.item
        property: "presentation"
        value: root.focusedWidgetActive ? "peek" : "compact"
        when: primaryWidgetLoader.item !== null
    }

    Item {
        id: primaryWidgetViewport

        opacity: root.focusedWidgetActive ? root.focusedPresentationPresence : (root.primaryWidgetVisible ? 1.0 : 0.0)
        scale: root.focusedWidgetActive ? 0.94 + root.focusedPresentationPresence * 0.06 : 1.0
        enabled: root.primaryWidgetVisible
        z: 1
        x: root.focusedWidgetActive
            ? root.liveLayout.otherContentStartOffset + Math.max((root.liveLayout.otherContentWidth - width) / 2, 0)
            : root.baseStartOffset + root.clockPreferredWidth + (root.primaryWidgetVisible ? root.baseSpacing : 0)
        width: root.focusedWidgetActive ? root.focusedWidgetViewportWidth : (root.primaryWidgetVisible ? root.primaryPreferredWidth : 0)
        height: root.height
        clip: true

        Loader {
            id: primaryWidgetLoader

            source: root.primaryWidgetSource
            asynchronous: false

            x: root.focusedWidgetActive ? (parent.width - width) / 2 : 0
            y: 0
            width: root.focusedWidgetActive ? root.focusedWidgetWidth : parent.width
            height: parent.height

            onLoaded: {
                root.syncWidgetInputs()

                if (root.focusedWidgetActive && !Boolean(item?.widgetVisible ?? false))
                    Qt.callLater(root.leaveFocusedWidgetPeek)
            }
        }
    }

    Loader {
        id: splitCompanionLoader

        source: root.splitCompanionSource
        asynchronous: false

        visible: opacity > 0.001
        opacity: root.splitCompanionReady ? root.focusedPresentationPresence * root.splitProgress : 0.0
        scale: 0.86 + root.splitProgress * 0.14
        enabled: root.splitCompanionReady && root.splitProgress > 0.9
        z: 2
        x: root.liveLayout.pieceContentStartOffset
        y: 0
        width: root.splitPlan.success ? root.liveLayout.pieceContentWidth : 0
        height: root.height

        onLoaded: root.syncWidgetInputs()
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

    onSplitProgressChanged: {
        Qt.callLater(root.reconcileNotificationPresentation)

        if (root.splitProgress <= 0.001 && !root.notificationData)
            root.clearRetainedNotification()
    }

    onFocusedWidgetActiveChanged: {
        root.syncWidgetInputs()
        if (root.focusedWidgetActive) {
            root._focusedBackPending = false
            if (root.primaryWidgetReady && !root.primaryWidgetVisible)
                Qt.callLater(root.leaveFocusedWidgetPeek)
        }
    }

    onPrimaryWidgetVisibleChanged: {
        if (root.focusedWidgetActive && root.primaryWidgetReady && !root.primaryWidgetVisible)
            root.leaveFocusedWidgetPeek()
    }

    onWidgetStatesChanged: root.syncWidgetInputs()

    Connections {
        target: splitCompanionLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            const request = root.splitCompanionSpec?.activationRequest
            if (request)
                root.sceneRequested(Object.assign({}, request))
        }

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested(root.splitCompanionWidgetId, patch)
        }
    }

    Connections {
        target: primaryWidgetLoader.item
        ignoreUnknownSignals: true

        function onActivated() {
            if (root.focusedWidgetActive)
                root.leaveFocusedWidgetPeek()
            else
                root.enterFocusedWidgetPeek(root.primaryWidgetId)
        }

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested(root.primaryWidgetId, patch)
        }
    }
}
