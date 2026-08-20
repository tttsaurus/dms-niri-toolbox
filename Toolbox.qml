import QtQuick
import Quickshell.Wayland

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

    readonly property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled ?? false

    readonly property int islandGeometryInset: {
        const value = Number(pluginData.islandGeometryInset ?? 5)
        return Number.isFinite(value) ? Math.max(0, Math.floor(value)) : 5
    }

    readonly property int islandInitialIdleWidth: {
        const value = Number(pluginData.islandReservedWidth ?? 168)
        return Number.isFinite(value) ? Math.max(1, Math.floor(value)) : 168
    }

    readonly property int islandCompactMaxWidth: {
        const value = Number(pluginData.islandCompactMaxWidth ?? 360)
        const parsed = Number.isFinite(value) ? Math.floor(value) : 360
        return Math.max(root.islandInitialIdleWidth, parsed)
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
        const value = pluginData.baseColorCompact ?? "#000000"
        if (typeof value !== "string")
            return "#000000"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#000000"
    }

    readonly property color glowColorCompact: {
        const value = pluginData.glowColorCompact ?? "#1b3554"
        if (typeof value !== "string")
            return "#1b3554"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#1b3554"
    }

    readonly property color edgeColorCompact: {
        const value = pluginData.edgeColorCompact ?? "#9fb8db"
        if (typeof value !== "string")
            return "#9fb8db"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#9fb8db"
    }

    readonly property int shadowWidthCompact: {
        const value = Number(pluginData.shadowWidthCompact ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityCompact: {
        const value = Number(pluginData.shadowIntensityCompact ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? value : 0.3));
    }

    readonly property bool interiorGlowCompact: pluginData.interiorGlowCompact ?? true
    readonly property bool innerEdgeHighlightCompact: pluginData.innerEdgeHighlightCompact ?? true
    readonly property bool followDmsColorSettingsCompact: pluginData.followDmsColorSettingsCompact ?? false

    // peek mode shader settings
    
    readonly property color baseColorPeek: {
        const value = pluginData.baseColorPeek ?? "#000000"
        if (typeof value !== "string")
            return "#000000"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#000000"
    }

    readonly property color glowColorPeek: {
        const value = pluginData.glowColorPeek ?? "#1b3554"
        if (typeof value !== "string")
            return "#1b3554"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#1b3554"
    }

    readonly property color edgeColorPeek: {
        const value = pluginData.edgeColorPeek ?? "#9fb8db"
        if (typeof value !== "string")
            return "#9fb8db"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#9fb8db"
    }

    readonly property int shadowWidthPeek: {
        const value = Number(pluginData.shadowWidthPeek ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityPeek: {
        const value = Number(pluginData.shadowIntensityPeek ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? value : 0.3));
    }

    readonly property bool interiorGlowPeek: pluginData.interiorGlowPeek ?? true
    readonly property bool innerEdgeHighlightPeek: pluginData.innerEdgeHighlightPeek ?? true
    readonly property bool followDmsColorSettingsPeek: pluginData.followDmsColorSettingsPeek ?? false

    // expanded mode shader settings
    
    readonly property color baseColorExpanded: {
        const value = pluginData.baseColorExpanded ?? "#000000"
        if (typeof value !== "string")
            return "#000000"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#000000"
    }

    readonly property color glowColorExpanded: {
        const value = pluginData.glowColorExpanded ?? "#1b3554"
        if (typeof value !== "string")
            return "#1b3554"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#1b3554"
    }

    readonly property color edgeColorExpanded: {
        const value = pluginData.edgeColorExpanded ?? "#9fb8db"
        if (typeof value !== "string")
            return "#9fb8db"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#9fb8db"
    }

    readonly property int shadowWidthExpanded: {
        const value = Number(pluginData.shadowWidthExpanded ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityExpanded: {
        const value = Number(pluginData.shadowIntensityExpanded ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? value : 0.3));
    }

    readonly property bool interiorGlowExpanded: pluginData.interiorGlowExpanded ?? true
    readonly property bool innerEdgeHighlightExpanded: pluginData.innerEdgeHighlightExpanded ?? true
    readonly property bool followDmsColorSettingsExpanded: pluginData.followDmsColorSettingsExpanded ?? false

    // ------------------------------------------------------------

    // not a config: live per-screen reservation exported by IslandBarReservation
    readonly property real islandReservedWidth: islandBarReservation.reservedWidth

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

    // // keep the island's overlay layer strictly above the bar
    // readonly property var barLayerShell: root.blurBarWindow ? root.blurBarWindow.WlrLayershell : null

    // Binding {
    //     target: root.barLayerShell
    //     property: "layer"
    //     value: WlrLayer.Top
    //     when: root.dynamicIslandEnabled && root.barLayerShell !== null
    //     restoreMode: Binding.RestoreBinding
    // }

    IslandBarReservation {
        id: islandBarReservation

        toolboxRoot: root
        initialWidth: root.islandInitialIdleWidth
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
