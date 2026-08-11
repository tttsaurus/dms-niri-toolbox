import QtQuick
import Quickshell

import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property bool islandEnabled: pluginData.dynamicIslandEnabled !== undefined ? pluginData.dynamicIslandEnabled : true

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
        model: root.islandEnabled ? Quickshell.screens : []

        IslandWindow {
            barAnchor: root.barAnchorFor(modelData.name)
        }
    }
}
