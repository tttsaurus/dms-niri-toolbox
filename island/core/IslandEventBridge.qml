import QtQuick

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
                || event.navigation != null
                || event.notificationPolicy != null) {

            console.warn("[IslandEventBridge] notification request ignores presentation, geometry, and navigation fields")
        }

        const ttl = root.positiveFinite(event.ttl, 3000)

        return {
            type: type,
            ttl: Math.floor(ttl),
            payload: root.objectCopy(event.payload)
        }
    }

    function parseWidgetRequest(event) {
        const widgetId = String(event.widgetId ?? "").trim()

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
            patch: operation === "patch" ? root.objectCopy(event.patch) : ({})
        }
    }

    function dispatch(event) {
        if (!event)
            return

        const requestType = String(event.request ?? "").trim()

        switch (requestType) {
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
            default:
                console.warn("[IslandEventBridge] unknown or missing request path: ", requestType)
        }
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
}
