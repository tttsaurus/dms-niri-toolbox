import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

import "components"

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

    SectionDivider {
        width: parent.width
        horizontalInset: 0
    }

    ToggleSetting {
        settingKey: "displaysPillText"

        label: "Displays Pill Text"
        description: "Show the text on the Toolbox pill"

        defaultValue: true
    }

    StringSetting {
        settingKey: "pillDisplayText"

        label: "Pill Display Text"
        description: "The text to display on the Toolbox pill"

        placeholder: "Toolbox"
        defaultValue: "Toolbox"
    }

    SectionDivider {
        width: parent.width
        horizontalInset: 0
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

    ToggleSetting {
        settingKey: "showDynamicIslandPage"

        label: "Dynamic Island"
        description: "Show the Dynamic Island in Toolbox"

        defaultValue: true
    }

    SectionDivider {
        width: parent.width
        horizontalInset: 0
    }

    StyledText {
        width: parent.width

        text: "Dynamic Island"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "dynamicIslandEnabled"

        label: "Enable Dynamic Island"
        description: "Show the Toolbox Dynamic Island overlay at the top-center of each display"

        defaultValue: false
    }
}