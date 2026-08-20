import QtQuick

Item {
    id: root

    required property url notificationSource
    property var notificationData: null
    property bool notificationVisible: false
    property int notificationRevision: 0
    property real splitProgress: 0.0
    property string preferredSide: "right"

    readonly property bool sourceMatches:
        String(root.notificationSource).length > 0
        && String(root._rendererSource) === String(root.notificationSource)
    readonly property bool rendererReady:
        root.sourceMatches
        && rendererLoader.status === Loader.Ready
        && rendererLoader.item !== null
    readonly property bool notificationReady:
        root.notificationData !== null
        && root._renderedNotificationData === root.notificationData
        && root.rendererReady

    readonly property real minimumWidthHint: root.rendererReady
        ? root.positiveDimension(rendererLoader.item?.minimumWidthHint, root.preferredWidthHint)
        : 1
    readonly property real preferredWidthHint: root.rendererReady
        ? root.positiveDimension(rendererLoader.item?.preferredWidthHint ?? rendererLoader.item?.implicitWidth, 1)
        : 1
    readonly property real preferredHeightHint: root.rendererReady
        ? root.positiveDimension(rendererLoader.item?.preferredHeightHint ?? rendererLoader.item?.implicitHeight, 36)
        : 36
    readonly property string preferredSideHint: String(rendererLoader.item?.preferredSideHint ?? root.preferredSide) === "left"
        ? "left"
        : "right"

    readonly property bool colorHintActive: root.notificationReady && (
            root.notificationPresented
            || root.presentationProgress > 0.001
            || root.normalizedSplitProgress > 0.001
        )

    readonly property var baseColorHint: root.colorHintActive
        ? (rendererLoader.item?.baseColorHint ?? null)
        : null

    readonly property var glowColorHint: root.colorHintActive
        ? (rendererLoader.item?.glowColorHint ?? null)
        : null

    readonly property var edgeColorHint: root.colorHintActive
        ? (rendererLoader.item?.edgeColorHint ?? null)
        : null

    readonly property bool notificationPresented: root.notificationVisible && root.notificationReady
    readonly property real normalizedSplitProgress: Math.max(0, Math.min(1, Number(root.splitProgress) || 0))
    readonly property real visualProgress: Math.min(root.presentationProgress, Math.sqrt(root.normalizedSplitProgress))

    property real presentationProgress: root.notificationPresented ? 1.0 : 0.0
    property url _rendererSource: ""
    property var _renderedNotificationData: null

    opacity: root.visualProgress
    scale: 0.92 + root.presentationProgress * 0.08
    transformOrigin: root.preferredSideHint === "left" ? Item.Right : Item.Left
    y: -3.0 * (1.0 - root.presentationProgress)
    visible: opacity > 0.001
    enabled: false

    Behavior on presentationProgress {
        NumberAnimation {
            duration: root.notificationPresented ? 220 : 180
            easing.type: root.notificationPresented ? Easing.OutCubic : Easing.InCubic
        }
    }

    function positiveDimension(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    function stageNotification() {
        if (!root.notificationData || String(root.notificationSource).length === 0)
            return

        if (String(root._rendererSource) !== String(root.notificationSource))
            root._rendererSource = root.notificationSource

        root._renderedNotificationData = root.notificationData
    }

    function releaseRenderedData() {
        if (root.notificationData
                || root.presentationProgress > 0.001
                || root.normalizedSplitProgress > 0.001) return

        root._renderedNotificationData = null
    }

    Loader {
        id: rendererLoader

        anchors.fill: parent
        source: root._rendererSource
        asynchronous: false

        onLoaded: root.stageNotification()
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[IslandNotificationHost] renderer load failed: ", source)
        }
    }

    Binding {
        target: rendererLoader.item
        property: "notificationData"
        value: root._renderedNotificationData
        when: rendererLoader.item !== null && typeof rendererLoader.item.notificationData !== "undefined"
    }

    onNotificationDataChanged: {
        root.stageNotification()
        root.releaseRenderedData()
    }
    onNotificationSourceChanged: root.stageNotification()
    onNotificationRevisionChanged: root.stageNotification()
    onPresentationProgressChanged: root.releaseRenderedData()
    onNormalizedSplitProgressChanged: root.releaseRenderedData()

    Component.onCompleted: root.stageNotification()
}
