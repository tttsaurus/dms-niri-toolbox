import QtQuick
import Quickshell

import qs.Common
import qs.Modules.Plugins

import "core" as Core

PluginComponent {
    id: root

    readonly property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled ?? true
    readonly property int islandReservedWidth: {
        const value = Number(pluginData.islandReservedWidth ?? 168)
        return Number.isFinite(value) ? Math.floor(value) : 168
    }

    property int barAnchorRevision: 0

    function barAnchorFor(screenName) {
        // getGlobalVar() is not a reactive QML property
        // reading the revision makes this function's callers re-evaluate when the published metrics change
        root.barAnchorRevision

        if (!pluginService || !pluginId)
            return null

        const all = pluginService.getGlobalVar(
            pluginId,
            "barAnchorGeometry",
            {}
        )

        return all[screenName] || null
    }

    Core.IslandController {
        id: islandController
    }

    Core.IslandEventBridge {
        pluginService: root.pluginService
        pluginId: root.pluginId

        onEventReceived: event => islandController.push(event)
        onClearRequested: islandController.clear()
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
            compactWidth: root.islandReservedWidth
        }
    }
}
