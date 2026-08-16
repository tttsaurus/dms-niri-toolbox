import QtQuick

Item {
    id: root

    visible: false
    width: 0
    height: 0

    readonly property string mode: _mode
    readonly property var sceneContext: _sceneContext
    readonly property var currentNotification: _currentNotification
    readonly property int queuedNotificationCount: _notificationQueue.length
    readonly property bool notificationsSuspended: _notificationsSuspended
    readonly property var widgetStates: _widgetStates

    property string _mode: "compact"
    property var _sceneContext: ({})

    property var _currentNotification: null
    property var _notificationQueue: []
    property var _suspendedNotification: null
    property int _suspendedRemainingTtl: 0
    property bool _notificationsSuspended: false
    property double _notificationDeadline: 0

    property var _widgetStates: ({})

    Timer {
        id: notificationTimer

        repeat: false
        onTriggered: root.finishCurrentNotification()
    }

    Timer {
        id: sceneTimer

        repeat: false
        onTriggered: root.finishSceneLease()
    }

    function normalizedPresentation(value, fallback) {
        const presentation = String(value ?? fallback ?? "compact")
        switch (presentation) {
            case "compact":
            case "peek":
            case "expanded":
                return presentation
            default:
                console.warn(
                    "[IslandController] unknown presentation: ",
                    presentation,
                    "- falling back to ",
                    fallback ?? "compact"
                )
                return String(fallback ?? "compact")
        }
    }

    function normalizedNotificationPolicy(value, presentation) {
        const policy = String(value ?? "")
        switch (policy) {
            case "keep":
            case "suspend":
            case "resume":
                return policy
            case "":
                if (presentation === "expanded")
                    return "suspend"
                if (root._notificationsSuspended)
                    return "resume"
                return "keep"
            default:
                console.warn(
                    "[IslandController] unknown notification policy: ",
                    policy,
                    "- using keep"
                )
                return "keep"
        }
    }

    function notificationTtl(notification) {
        const ttl = Number(notification?.ttl ?? 3000)
        return Number.isFinite(ttl) && ttl > 0 ? Math.floor(ttl) : 3000
    }

    function activateNotification(notification, ttlOverride) {
        if (!notification)
            return

        const next = Object.assign({}, notification)
        const override = Number(ttlOverride)
        const ttl = Number.isFinite(override) && override >= 0 ? Math.floor(override) : root.notificationTtl(next)

        notificationTimer.stop()
        root._currentNotification = next
        root._notificationDeadline = 0

        if (ttl > 0) {
            root._notificationDeadline = Date.now() + ttl
            notificationTimer.interval = ttl
            notificationTimer.start()
        }
    }

    function isMusicExclusivePresentation(presentation, context) {
        return presentation === "peek"
            && String(context?.exclusiveWidgetId ?? "") === "musicTrack"
    }

    function musicExclusivePeekActive() {
        return root.isMusicExclusivePresentation(root._mode, root._sceneContext)
    }

    function notificationPresentationAvailable() {
        return root._mode === "compact" || (root._mode === "peek" && !root.musicExclusivePeekActive())
    }

    function playNextNotification() {
        if (root._notificationsSuspended
                || !root.notificationPresentationAvailable()
                || root._currentNotification
                || root._notificationQueue.length === 0) return

        const queue = root._notificationQueue.slice()
        const next = queue.shift()
        root._notificationQueue = queue
        root.activateNotification(next)
    }

    function pushNotification(notification) {
        if (!notification)
            return

        const next = Object.assign({}, notification)


        if (root._notificationsSuspended
                || !root.notificationPresentationAvailable()
                || root._currentNotification) {

            const queue = root._notificationQueue.slice()
            queue.push(next)
            root._notificationQueue = queue
            return
        }

        root.activateNotification(next)
    }

    function finishCurrentNotification() {
        notificationTimer.stop()
        root._currentNotification = null
        root._notificationDeadline = 0
        root.playNextNotification()
    }

    function dismissCurrentNotification() {
        root.finishCurrentNotification()
    }

    function suspendNotifications() {
        if (root._notificationsSuspended)
            return

        root._notificationsSuspended = true
        notificationTimer.stop()

        if (!root._currentNotification)
            return

        root._suspendedNotification = root._currentNotification
        root._suspendedRemainingTtl = root._notificationDeadline > 0 ? Math.max(1, Math.ceil(root._notificationDeadline - Date.now())) : 0
        root._currentNotification = null
        root._notificationDeadline = 0
    }

    function resumeNotifications() {
        if (!root._notificationsSuspended) {
            root.playNextNotification()
            return
        }

        root._notificationsSuspended = false

        if (root._suspendedNotification) {
            const suspended = root._suspendedNotification
            const remainingTtl = root._suspendedRemainingTtl

            root._suspendedNotification = null
            root._suspendedRemainingTtl = 0
            root.activateNotification(suspended, remainingTtl)
            return
        }

        root.playNextNotification()
    }

    function clearNotifications() {
        notificationTimer.stop()
        root._currentNotification = null
        root._notificationQueue = []
        root._suspendedNotification = null
        root._suspendedRemainingTtl = 0
        root._notificationsSuspended = false
        root._notificationDeadline = 0
    }

    function requestScene(request, legacyContext) {
        const normalizedRequest = typeof request === "string" ? { presentation: request, context: legacyContext ?? ({}) } : Object.assign({}, request ?? ({}))

        const presentation = root.normalizedPresentation(normalizedRequest.presentation, root._mode)
        const sceneContext = Object.assign({}, normalizedRequest.context ?? ({}))

        sceneTimer.stop()

        const policy = root.normalizedNotificationPolicy(normalizedRequest.notificationPolicy, presentation)

        if (policy === "suspend")
            root.suspendNotifications()

        root._mode = presentation
        root._sceneContext = sceneContext

        if (policy === "resume")
            root.resumeNotifications()
        else
            root.playNextNotification()

        const ttl = Number(normalizedRequest.ttl ?? 0)
        if (Number.isFinite(ttl) && ttl > 0) {
            sceneTimer.interval = Math.floor(ttl)
            sceneTimer.start()
        }
    }

    function finishSceneLease() {
        root.requestScene({
            presentation: "compact",
            context: {},
            notificationPolicy: root._notificationsSuspended ? "resume" : "keep"
        })
    }

    function widgetStateFor(widgetId) {
        const id = String(widgetId ?? "")
        return id.length > 0 ? (root._widgetStates[id] ?? ({})) : ({})
    }

    function patchWidgetState(widgetId, patch) {
        const id = String(widgetId ?? "")
        if (id.length === 0 || !patch)
            return

        const nextStates = Object.assign({}, root._widgetStates)
        nextStates[id] = Object.assign({}, nextStates[id] ?? ({}), patch)
        root._widgetStates = nextStates
    }

    function resetWidgetState(widgetId) {
        const id = String(widgetId ?? "")
        if (id.length === 0 || root._widgetStates[id] === undefined)
            return

        const nextStates = Object.assign({}, root._widgetStates)
        delete nextStates[id]
        root._widgetStates = nextStates
    }

    function applyWidgetRequest(request) {
        if (!request)
            return

        const widgetId = String(request.widgetId ?? "")
        switch (String(request.operation ?? "patch")) {
            case "patch":
                root.patchWidgetState(widgetId, request.patch ?? ({}))
                return
            case "reset":
                root.resetWidgetState(widgetId)
                return
            default:
                console.warn("[IslandController] unsupported widget request operation: ", request.operation)
        }
    }

    function acceptRequest(requestType, request) {
        switch (String(requestType ?? "")) {
            case "scene":
                root.requestScene(request)
                return
            case "notification":
                root.pushNotification(request)
                return
            case "widget":
                root.applyWidgetRequest(request)
                return
            case "clear":
                root.clear()
                return
            default:
                console.warn("[IslandController] unsupported bridge request: ", requestType)
        }
    }

    function clear() {
        sceneTimer.stop()
        root.clearNotifications()
        root._sceneContext = ({})
        root._mode = "compact"
    }
}