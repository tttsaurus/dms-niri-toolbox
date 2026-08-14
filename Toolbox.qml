import QtQuick

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

import "components"

PluginComponent {
    id: root

    layerNamespacePlugin: "toolbox"

    // -------------------- Config Reading --------------------

    readonly property bool displaysText: pluginData.displaysPillText ?? true
    readonly property string displayText: pluginData.pillDisplayText || "Toolbox"

    readonly property bool showSettingsPage: pluginData.showSettingsPage ?? true
    readonly property bool showJavaPage: pluginData.showJavaPage ?? true
    readonly property bool showNiriShaderPage: pluginData.showNiriShaderPage ?? true
    readonly property bool showDynamicIslandPage: pluginData.showDynamicIslandPage ?? true

    readonly property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled ?? true
    
    readonly property int islandReservedWidth: {
        const value = Number(pluginData.islandReservedWidth ?? 168)
        return Number.isFinite(value) ? Math.floor(value) : 168
    }

    readonly property int islandCompactRadius: {
        const value = Number(pluginData.islandCompactRadius ?? 18)
        return Number.isFinite(value) ? Math.floor(value) : 18
    }

    readonly property int islandPeekRadius: {
        const value = Number(pluginData.islandPeekRadius ?? 18)
        return Number.isFinite(value) ? Math.floor(value) : 18
    }

    readonly property int islandExpandedRadius: {
        const value = Number(pluginData.islandExpandedRadius ?? 28)
        return Number.isFinite(value) ? Math.floor(value) : 28
    }

    // compact mode shader settings
    
    readonly property color baseColorCompact: {
        const value = pluginData.baseColorCompact ?? "#111b34"
        if (typeof value !== "string")
            return "#111b34"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#111b34"
    }

    readonly property color glowColorCompact: {
        const value = pluginData.glowColorCompact ?? "#285b9c"
        if (typeof value !== "string")
            return "#285b9c"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#285b9c"
    }

    readonly property color edgeColorCompact: {
        const value = pluginData.edgeColorCompact ?? "#b8d8ff"
        if (typeof value !== "string")
            return "#b8d8ff"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#b8d8ff"
    }

    readonly property int shadowWidthCompact: {
        const value = Number(pluginData.shadowWidthCompact ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityCompact: {
        const value = Number(pluginData.shadowIntensityCompact ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? Math.floor(value) : 0.3));
    }

    readonly property bool interiorGlowCompact: pluginData.interiorGlowCompact ?? true
    readonly property bool innerEdgeHighlightCompact: pluginData.innerEdgeHighlightCompact ?? true

    // ------------------------------------------------------------

    property string selectedPage: ""

    function isPageEnabled(page) {
        switch (page) {
            case "settings":
                return showSettingsPage

            case "java":
                return showJavaPage

            case "niriShader":
                return showNiriShaderPage

            case "dynamicIsland":
                return showDynamicIslandPage

            default:
                return false
        }
    }

    function firstEnabledPage() {
        if (showSettingsPage)
            return "settings"

        if (showJavaPage)
            return "java"

        if (showNiriShaderPage)
            return "niriShader"

        if (showDynamicIslandPage)
            return "dynamicIsland"

        return ""
    }

    function ensureValidPage() {
        if (!isPageEnabled(selectedPage))
            selectedPage = firstEnabledPage()
    }

    function saveSetting(key, value) {
        pluginService.savePluginData(
            pluginId,
            key,
            value
        )
    }

    onShowSettingsPageChanged: ensureValidPage()
    onShowJavaPageChanged: ensureValidPage()
    onShowNiriShaderPageChanged: ensureValidPage()
    onShowDynamicIslandPageChanged: ensureValidPage()

    Component.onCompleted: ensureValidPage()

    IslandBarReservation {
        toolboxRoot: root

        reservedWidth: root.islandReservedWidth
    }

    horizontalBarPill: Component {
        ToolboxBarPill {
            toolboxRoot: root
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "widgets"
                size: Theme.iconSize
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.displayText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.displaysText
            }
        }
    }

    popoutContent: Component {
        ToolboxPopout {
            toolboxRoot: root
        }
    }

    popoutWidth: 720
    popoutHeight: 480
}