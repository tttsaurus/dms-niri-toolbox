import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    required property var pluginService
    required property string pluginId

    signal requestReceived(string requestType, var request)

    property string lastGlobalToken: ""

    function positiveFinite(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    function objectCopy(value) {
        return value && typeof value === "object" ? Object.assign({}, value) : ({})
    }

    function parseSceneRequest(event) {
        const context = root.objectCopy(event.context ?? event.payload)

        const width = root.positiveFinite(event.width ?? event.widthHint ?? context.widthHint, 0)
        const height = root.positiveFinite(event.height ?? event.heightHint ?? context.heightHint, 0)

        if (width > 0)
            context.widthHint = width
        if (height > 0)
            context.heightHint = height

        const ttl = root.positiveFinite(event.ttl, 0)

        return {
            presentation: String(event.presentation ?? event.mode ?? "peek"),
            context: context,
            notificationPolicy: String(event.notificationPolicy ?? ""),
            ttl: ttl > 0 ? Math.floor(ttl) : 0
        }
    }

    function parseNotificationRequest(event) {
        const type = String(event.type ?? "").trim()

        if (type.length === 0) {
            console.warn("[IslandEventBridge] notification request requires a type")
            return null
        }

        if (event.presentation != null
                || event.mode != null
                || event.width != null
                || event.widthHint != null
                || event.height != null
                || event.heightHint != null
                || event.notificationPolicy != null) {

            console.warn("[IslandEventBridge] notification request ignores scene presentation/geometry fields")
        }

        const ttl = root.positiveFinite(event.ttl, 3000)

        return {
            type: type,
            ttl: Math.floor(ttl),
            payload: root.objectCopy(event.payload)
        }
    }

    function parseWidgetRequest(event) {
        const widgetId = String(event.widgetId ?? event.id ?? "").trim()

        if (widgetId.length === 0) {
            console.warn("[IslandEventBridge] widget request requires widgetId")
            return null
        }

        const operation = String(event.operation ?? "patch")
        if (operation !== "patch" && operation !== "reset") {
            console.warn("[IslandEventBridge] unsupported widget operation: ", operation)
            return null
        }

        return {
            widgetId: widgetId,
            operation: operation,
            patch: operation === "patch" ? root.objectCopy(event.patch ?? event.payload) : ({})
        }
    }

    function dispatch(event) {
        if (!event)
            return

        if (event.action === "clear" && event.request == null) {
            root.requestReceived("clear", {})
            return
        }

        const requestType = String(event.request ?? "").trim()

        switch (requestType) {
            case "scene": {
                root.requestReceived("scene", root.parseSceneRequest(event))
                return
            }
            case "notification": {
                const notification = root.parseNotificationRequest(event)
                if (notification)
                    root.requestReceived("notification", notification)
                return
            }
            case "widget": {
                const widgetRequest = root.parseWidgetRequest(event)
                if (widgetRequest)
                    root.requestReceived("widget", widgetRequest)
                return
            }
            case "clear":
                root.requestReceived("clear", {})
                return
            default:
                console.warn("[IslandEventBridge] unknown or missing request path: ", requestType)
        }
    }

    // permanent ingress contract
    function accept(event) {
        root.dispatch(event)
    }

    function consumeGlobalEvent() {
        if (!root.pluginService || !root.pluginId)
            return

        const envelope = root.pluginService.getGlobalVar(root.pluginId, "islandEvent", null)
        if (!envelope)
            return

        if (envelope.token != null) {
            const token = String(envelope.token)
            if (token === root.lastGlobalToken)
                return

            root.lastGlobalToken = token
        }

        root.dispatch(envelope.event ?? envelope)
    }

    Connections {
        target: root.pluginService

        function onGlobalVarChanged(changedPluginId, varName) {
            if (changedPluginId === root.pluginId && varName === "islandEvent")
                root.consumeGlobalEvent()
        }
    }

    IpcHandler {
        target: "toolboxIslandDebug"

        function peek(message: string): void {
            root.dispatch({
                request: "scene",
                mode: "peek",
                width: 280,
                ttl: 1800,
                context: {
                    message: message
                }
            })
        }

        function peekSized(message: string, width: real, ttl: int): void {
            root.dispatch({
                request: "scene",
                mode: "peek",
                width: width,
                ttl: ttl,
                context: {
                    message: message
                }
            })
        }

        function expand(message: string): void {
            root.dispatch({
                request: "scene",
                mode: "expanded",
                width: 520,
                height: 260,
                notificationPolicy: "suspend",
                context: {
                    message: message
                }
            })
        }

        function expandSized(message: string, width: real, height: real): void {
            root.dispatch({
                request: "scene",
                mode: "expanded",
                width: width,
                height: height,
                notificationPolicy: "suspend",
                context: {
                    message: message
                }
            })
        }

        function pushJson(json: string): string {
            try {
                root.dispatch(JSON.parse(json))
                return "ok"
            } catch (error) {
                return "invalid JSON: " + error
            }
        }

        function clear(): void {
            root.requestReceived("clear", {})
        }
    }
}