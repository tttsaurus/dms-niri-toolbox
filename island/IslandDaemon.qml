import QtQuick
import Quickshell

import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property bool islandEnabled: pluginData.dynamicIslandEnabled !== undefined ? pluginData.dynamicIslandEnabled : true

    property int barGeometryRevision: 0

    function barGeometryFor(screenName) {
        barGeometryRevision

        if (!pluginService || !pluginId)
            return null

        const all =
            pluginService.getGlobalVar(
                pluginId,
                "barGeometry",
                {}
            )

        return all[screenName] || null
    }

    Connections {
        target: root.pluginService

        function onGlobalVarChanged(changedPluginId, varName) {
            if (changedPluginId === root.pluginId && varName === "barGeometry") {
                root.barGeometryRevision++
            }
        }
    }

    Variants {
        model: root.islandEnabled ? Quickshell.screens : []

        IslandWindow {}
    }
}