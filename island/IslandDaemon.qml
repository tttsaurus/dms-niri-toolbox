import QtQuick
import Quickshell

import qs.Modules.Plugins
import qs.Services

import "core" as Core

PluginComponent {
    id: root

    readonly property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled ?? false

    readonly property int islandInitialIdleWidth: {
        const value = Number(pluginData.islandReservedWidth ?? 168)
        return Number.isFinite(value) ? Math.max(1, Math.floor(value)) : 168
    }

    readonly property int islandCompactMaxWidth: {
        const value = Number(pluginData.islandCompactMaxWidth ?? 360)
        const parsed = Number.isFinite(value) ? Math.floor(value) : 360
        return Math.max(root.islandInitialIdleWidth, parsed)
    }

    property int barAnchorRevision: 0
    property bool previousPluggedIn: false

    Component.onCompleted: root.previousPluggedIn = BatteryService.isPluggedIn

    function barAnchorFor(screenName) {
        // getGlobalVar() is not a reactive QML property. Reading the revision
        // makes callers re-evaluate when the published metrics change
        root.barAnchorRevision

        if (!pluginService || !pluginId)
            return null

        const all = pluginService.getGlobalVar(pluginId, "barAnchorGeometry", {})

        return all[screenName] || null
    }

    function publishReservation(screenName, width) {
        if (!root.pluginService || !root.pluginId || !screenName)
            return

        const number = Number(width)
        const reservation = Number.isFinite(number) ? Math.max(root.islandInitialIdleWidth, Math.round(number)) : root.islandInitialIdleWidth

        const current = root.pluginService.getGlobalVar(root.pluginId, "islandReservationWidths", {})

        if (Number(current[screenName]) === reservation)
            return

        const next = Object.assign({}, current)
        next[screenName] = reservation

        root.pluginService.setGlobalVar(root.pluginId, "islandReservationWidths", next)
    }

    Core.IslandController {
        id: islandController
    }

    Core.IslandEventBridge {
        pluginService: root.pluginService
        pluginId: root.pluginId

        onRequestReceived: (requestType, request) => islandController.acceptRequest(requestType, request)
    }

    Connections {
        target: BatteryService

        function onIsPluggedInChanged() {
            const pluggedIn = BatteryService.isPluggedIn
            const wasPluggedIn = root.previousPluggedIn
            root.previousPluggedIn = pluggedIn

            if (BatteryService.suppressSound
                    || !root.dynamicIslandEnabled
                    || !BatteryService.batteryAvailable
                    || !pluggedIn
                    || wasPluggedIn) return

            islandController.acceptRequest("notification", {
                type: "powerConnected",
                ttl: 2000,
                payload: {
                    level: Math.round(BatteryService.batteryLevel)
                }
            })
        }
    }

    Connections {
        target: root.pluginService

        function onGlobalVarChanged(changedPluginId, varName) {
            if (changedPluginId === root.pluginId && varName === "barAnchorGeometry")
                root.barAnchorRevision++
        }
    }

    Variants {
        model: root.dynamicIslandEnabled ? Quickshell.screens : []

        IslandWindow {
            controller: islandController
            barAnchor: root.barAnchorFor(modelData.name)
            compactWidth: root.islandInitialIdleWidth
            compactMaximumWidth: root.islandCompactMaxWidth

            Component.onCompleted: {
                root.publishReservation(modelData.name, reservationWidth)
            }

            Component.onDestruction: {
                root.publishReservation(modelData.name, root.islandInitialIdleWidth)
            }

            onReservationWidthChanged: {
                root.publishReservation(modelData.name, reservationWidth)
            }
        }
    }
}
