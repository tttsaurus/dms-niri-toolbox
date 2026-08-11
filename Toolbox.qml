import QtQuick

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

import "components"

PluginComponent {
    id: root

    layerNamespacePlugin: "toolbox"

    property string displayText: "Toolbox"

    property bool showSettingsPage: pluginData.showSettingsPage !== undefined ? pluginData.showSettingsPage : true
    property bool showJavaPage: pluginData.showJavaPage !== undefined ? pluginData.showJavaPage : true
    property bool showNiriShaderPage: pluginData.showNiriShaderPage !== undefined ? pluginData.showNiriShaderPage : true

    property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled !== undefined ? pluginData.dynamicIslandEnabled : true
    property int islandReservedWidth: 168

    property string selectedPage: ""

    function isPageEnabled(page) {
        switch (page) {
            case "settings":
                return showSettingsPage

            case "java":
                return showJavaPage

            case "niriShader":
                return showNiriShaderPage

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