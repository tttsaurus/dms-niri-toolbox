import QtQuick
import Quickshell

import qs.Modules.Plugins
import qs.Common

PluginComponent {
    id: root

    readonly property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled ?? true
    readonly property int islandReservedWidth: {
        const value = Number(pluginData.islandReservedWidth ?? 168)
        return Number.isFinite(value) ? Math.floor(value) : 168
    }

    property int barAnchorRevision: 0

    function barAnchorFor(screenName) {
        barAnchorRevision

        if (!pluginService || !pluginId)
            return null

        const all =
            pluginService.getGlobalVar(
                pluginId,
                "barAnchorGeometry",
                {}
            )

        return all[screenName] || null
    }

    Connections {
        target: root.pluginService

        function onGlobalVarChanged(changedPluginId, varName) {
            if (changedPluginId === root.pluginId && varName === "barAnchorGeometry") {
                root.barAnchorRevision++
            }
        }
    }

    Variants {
        model: root.dynamicIslandEnabled ? Quickshell.screens : []

        IslandWindow {
            barAnchor: root.barAnchorFor(modelData.name)
            compactWidth: root.islandReservedWidth
        }
    }
}
