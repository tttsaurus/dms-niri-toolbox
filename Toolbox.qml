import QtQuick

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

import "components"

PluginComponent {
    id: root

    layerNamespacePlugin: "toolbox"

    readonly property bool displaysText: pluginData.displaysPillText ?? true
    readonly property string displayText: pluginData.pillDisplayText ?? "Toolbox"

    readonly property bool showSettingsPage: pluginData.showSettingsPage ?? true
    readonly property bool showJavaPage: pluginData.showJavaPage ?? true
    readonly property bool showNiriShaderPage: pluginData.showNiriShaderPage ?? true
    readonly property bool showDynamicIslandPage: pluginData.showDynamicIslandPage ?? true

    readonly property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled ?? true
    readonly property int islandReservedWidth: {
        const value = Number(pluginData.islandReservedWidth ?? 168)
        return Number.isFinite(value) ? Math.floor(value) : 168
    }

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