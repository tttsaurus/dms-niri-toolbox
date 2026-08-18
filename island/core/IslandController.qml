import QtQuick

Item {
    id: root

    visible: false
    width: 0
    height: 0

    readonly property int accessDepth: root._accessChain.length
    readonly property var currentAccess: root.accessDepth > 0 ? root._accessChain[root.accessDepth - 1] : null
    readonly property var sceneState: root.currentAccess ?? root._rootScene
    readonly property string mode: String(root.sceneState?.presentation ?? "compact")
    readonly property var sceneContext: root.sceneState?.context ?? ({})

    readonly property var currentNotification: root._currentNotification
    readonly property var widgetStates: root._widgetStates

    property var _rootScene: ({
        presentation: "compact",
        context: ({})
    })
    property var _accessChain: []
    property int _nextAccessId: 0

    property var _currentNotification: null
    property var _notificationQueue: []
    property var _suspendedNotification: null
    property int _suspendedRemainingTtl: 0
    property bool _notificationsSuspended: false
    property double _notificationDeadline: 0

    property var _widgetStates: ({})

    IslandContentRegistry {
        id: registry
    }

    Timer {
        id: notificationTimer

        repeat: false
        onTriggered: root.finishCurrentNotification()
    }

    function normalizedPresentation(value, fallback) {
        const fallbackPresentation = String(fallback ?? "compact")
        const presentation = String(value ?? fallbackPresentation)
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
                    fallbackPresentation
                )
                return fallbackPresentation
        }
    }

    function normalizedNavigation(value, fallback) {
        const fallbackNavigation = String(fallback ?? "replace")
        const navigation = String(value ?? fallbackNavigation)
        switch (navigation) {
            case "replace":
            case "push":
            case "back":
                return navigation
            default:
                console.warn(
                    "[IslandController] unknown navigation: ",
                    navigation,
                    "- using ",
                    fallbackNavigation
                )
                return fallbackNavigation
        }
    }

    function objectCopy(value) {
        return value && typeof value === "object" ? Object.assign({}, value) : ({})
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

    function notificationPresentationAvailable() {
        if (root.accessDepth > 0)
            return false

        return root.mode === "compact" || (root.mode === "peek" && String(root.sceneContext?.presentationRole ?? "") === "notificationOverflow")
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

    function createAccessFrame(request) {
        const widgetId = String(request?.widgetId ?? "").trim()
        if (widgetId.length === 0) {
            console.warn("[IslandController] Widget access requires widgetId")
            return null
        }

        if (!registry.isWidgetRegistered(widgetId)) {
            console.warn("[IslandController] unknown Widget access target: ", widgetId)
            return null
        }

        const presentation = root.normalizedPresentation(request?.presentation, "peek")
        if (presentation === "compact") {
            console.warn("[IslandController] Compact is the root Widget list and cannot be an access node")
            return null
        }

        const accessId = ++root._nextAccessId
        const context = root.objectCopy(request?.context)
        context.accessId = accessId
        context.widgetId = widgetId

        const widthHint = Number(request?.width ?? request?.widthHint ?? context.widthHint)
        const heightHint = Number(request?.height ?? request?.heightHint ?? context.heightHint)
        if (Number.isFinite(widthHint) && widthHint > 0)
            context.widthHint = widthHint
        if (Number.isFinite(heightHint) && heightHint > 0)
            context.heightHint = heightHint

        return {
            accessId: accessId,
            widgetId: widgetId,
            presentation: presentation,
            context: context
        }
    }

    function requestAccess(request) {
        const normalizedRequest = root.objectCopy(request)
        const navigation = root.normalizedNavigation(normalizedRequest.navigation, "push")

        if (navigation === "back") {
            root.navigateBack()
            return
        }

        const frame = root.createAccessFrame(normalizedRequest)
        if (!frame)
            return

        const chain = root._accessChain.slice()
        const enteringAccess = chain.length === 0

        if (navigation === "replace" && chain.length > 0)
            chain[chain.length - 1] = frame
        else
            chain.push(frame)

        if (enteringAccess || !root._notificationsSuspended)
            root.suspendNotifications()

        root._accessChain = chain
    }

    function resetRootPresentation() {
        root._rootScene = {
            presentation: "compact",
            context: ({})
        }

        if (root._notificationsSuspended)
            root.resumeNotifications()
        else
            root.playNextNotification()
    }

    function requestRootPresentation(request) {
        const normalizedRequest = root.objectCopy(request)

        if (root.accessDepth > 0) {
            console.warn("[IslandController] root presentation cannot replace an active Widget access")
            return
        }

        const presentation = root.normalizedPresentation(normalizedRequest.presentation, "compact")
        const context = root.objectCopy(normalizedRequest.context)
        delete context.accessId
        delete context.widgetId
        const role = String(context.presentationRole ?? "")

        if (presentation !== "compact" && !(presentation === "peek" && role === "notificationOverflow")) {
            console.warn("[IslandController] non-Compact root presentation is reserved for Notification overflow")
            return
        }

        root._rootScene = {
            presentation: presentation,
            context: presentation === "compact" ? ({}) : context
        }

        if (root._notificationsSuspended)
            root.resumeNotifications()
        else
            root.playNextNotification()
    }

    function navigateBack() {
        if (root._accessChain.length === 0) {
            if (root.mode !== "compact")
                root.resetRootPresentation()
            else if (root._notificationsSuspended)
                root.resumeNotifications()
            return
        }

        const chain = root._accessChain.slice()
        chain.pop()
        root._accessChain = chain

        if (root.accessDepth === 0)
            root.resumeNotifications()
        else if (!root._notificationsSuspended)
            root.suspendNotifications()
    }

    function dismissScene() {
        if (root.accessDepth > 0) {
            root.navigateBack()
            return
        }

        root.resetRootPresentation()
    }

    function patchWidgetState(widgetId, patch) {
        const id = String(widgetId ?? "")
        if (id.length === 0 || !patch || typeof patch !== "object")
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
                console.warn("[IslandController] unsupported Widget request operation: ", request.operation)
        }
    }

    function acceptRequest(requestType, request) {
        switch (String(requestType ?? "")) {
            case "notification":
                root.pushNotification(request)
                return
            case "widget":
                root.applyWidgetRequest(request)
                return
            default:
                console.warn("[IslandController] unsupported Bridge request: ", requestType)
        }
    }
}
