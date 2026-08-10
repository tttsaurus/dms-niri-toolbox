import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "toolbox"

    StyledText {
        width: parent.width

        text: "Toolbox Settings"

        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width

        text: "Configure the Toolbox widget and choose which pages are available."

        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText

        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width

        text: "Pages"

        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "showSettingsPage"

        label: "Settings"
        description: "Show the settings page in Toolbox"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showJavaPage"

        label: "Java Switch"
        description: "Show the Java environment switcher in Toolbox"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showNiriShaderPage"

        label: "Niri Shader"
        description: "Show the Niri shader manager in Toolbox"

        defaultValue: true
    }
}