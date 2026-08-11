import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    required property var pluginService
    required property string pluginId

    signal eventReceived(var event)
    signal clearRequested()

    property string lastGlobalToken: ""

    // permanent ingress contract for other QML/backend adapters:
    // emit eventReceived({ type, presentation, ttl?, payload? })
    function accept(event) {
        if (event)
            root.eventReceived(event)
    }

    function consumeGlobalEvent() {
        if (!root.pluginService || !root.pluginId)
            return

        const envelope = root.pluginService.getGlobalVar(
            root.pluginId,
            "islandEvent",
            null
        )

        if (!envelope)
            return

        if (envelope.token != null) {
            const token = String(envelope.token)
            if (token === root.lastGlobalToken)
                return

            root.lastGlobalToken = token
        }

        const event = envelope.event ?? envelope
        if (!event)
            return

        if (event.action === "clear") {
            root.clearRequested()
            return
        }

        root.eventReceived(event)
    }

    Connections {
        target: root.pluginService

        function onGlobalVarChanged(changedPluginId, varName) {
            if (changedPluginId === root.pluginId && varName === "islandEvent")
                root.consumeGlobalEvent()
        }
    }

    // permanent bash/debug ingress
    // these methods intentionally create only debug content
    // production providers should use the eventReceived contract
    IpcHandler {
        target: "toolboxIslandDebug"

        function peek(message: string): void {
            root.eventReceived({
                type: "debugPeek",
                presentation: "peek",
                ttl: 1800,
                payload: {
                    message: message,
                    width: 280
                }
            })
        }

        function peekSized(message: string, width: real, ttl: int): void {
            root.eventReceived({
                type: "debugPeek",
                presentation: "peek",
                ttl: ttl,
                payload: {
                    message: message,
                    width: width
                }
            })
        }

        function expand(message: string): void {
            root.eventReceived({
                type: "debugExpanded",
                presentation: "expanded",
                payload: {
                    message: message,
                    width: 520,
                    height: 260
                }
            })
        }

        function expandSized(message: string, width: real, height: real): void {
            root.eventReceived({
                type: "debugExpanded",
                presentation: "expanded",
                payload: {
                    message: message,
                    width: width,
                    height: height
                }
            })
        }

        function pushJson(json: string): string {
            try {
                const event = JSON.parse(json)
                root.eventReceived(event)
                return "ok"
            } catch (error) {
                return "invalid JSON: " + error
            }
        }

        function clear(): void {
            root.clearRequested()
        }
    }
}
