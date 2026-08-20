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

    SliderSetting {
        settingKey: "islandGeometryInset"

        label: "Island Geometry Inset"
        description: "Inward margin applied to the Island geometry"

        defaultValue: 5

        minimum: 0
        maximum: 10
        unit: "px"
    }

    SliderSetting {
        settingKey: "islandReservedWidth"

        label: "Island Initial Idle Width"
        description: "Initial compact/idle width. Active compact content may dynamically reserve more Dank Bar space"

        defaultValue: 168

        minimum: 80
        maximum: 200
        unit: "px"
    }

    SliderSetting {
        settingKey: "islandCompactMaxWidth"

        label: "Compact Notification Max Width"
        description: "Promote Widgets + Notification to Peek when their combined width exceeds this value; Widgets alone are not capped"

        defaultValue: 360

        minimum: 200
        maximum: 800
        unit: "px"
    }

    SliderSetting {
        settingKey: "islandCompactRadius"

        label: "Island Compact Mode Radius"
        description: "Radius for the compact Dynamic Island"

        defaultValue: 18

        minimum: 1
        maximum: 30
        unit: "px"
    }

    SliderSetting {
        settingKey: "islandPeekRadius"

        label: "Island Peek Mode Radius"
        description: "Radius for the peek Dynamic Island"

        defaultValue: 18

        minimum: 1
        maximum: 30
        unit: "px"
    }

    SliderSetting {
        settingKey: "islandExpandedRadius"

        label: "Island Expanded Mode Radius"
        description: "Radius for the expanded Dynamic Island"

        defaultValue: 28

        minimum: 10
        maximum: 300
        unit: "px"
    }

    SectionDivider {
        width: parent.width
        horizontalInset: 0
    }

    ColorSetting {
        settingKey: "baseColorCompact"

        label: "Base Color (Compact Mode)"
        description: "Base color of the Dynamic Island"

        defaultValue: "#000000"
    }

    ColorSetting {
        settingKey: "glowColorCompact"

        label: "Glow Color (Compact Mode)"
        description: "Color used for the interior glow and secondary highlights"

        defaultValue: "#1b3554"
    }

    ColorSetting {
        settingKey: "edgeColorCompact"

        label: "Edge Color (Compact Mode)"
        description: "Color used for edge highlights and specular lighting"

        defaultValue: "#9fb8db"
    }

    SliderSetting {
        settingKey: "shadowWidthCompact"

        label: "Shadow Width (Compact Mode)"
        description: "Width of the outer Dynamic Island shadow"

        defaultValue: 4

        minimum: 0
        maximum: 5

        unit: "px"
    }

    StringSetting {
        settingKey: "shadowIntensityCompact"

        label: "Shadow Intensity (Compact Mode)"
        description: "Shadow intensity from 0.0 to 0.9"

        placeholder: "0.0 - 0.9"
        defaultValue: "0.3"
    }

    ToggleSetting {
        settingKey: "interiorGlowCompact"

        label: "Interior Glow (Compact Mode)"
        description: "Enable the animated glow inside the Dynamic Island"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "innerEdgeHighlightCompact"

        label: "Inner Edge Highlight (Compact Mode)"
        description: "Enable the secondary highlight along the inner edge"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "followDmsColorSettingsCompact"

        label: "Follow DMS Color Settings (Compact Mode)"
        description: "Foloow DMS color settings for Glow/Edge color"

        defaultValue: false
    }

    SectionDivider {
        width: parent.width
        horizontalInset: 0
    }

    ColorSetting {
        settingKey: "baseColorPeek"

        label: "Base Color (Peek Mode)"
        description: "Base color of the Dynamic Island"

        defaultValue: "#000000"
    }

    ColorSetting {
        settingKey: "glowColorPeek"

        label: "Glow Color (Peek Mode)"
        description: "Color used for the interior glow and secondary highlights"

        defaultValue: "#1b3554"
    }

    ColorSetting {
        settingKey: "edgeColorPeek"

        label: "Edge Color (Peek Mode)"
        description: "Color used for edge highlights and specular lighting"

        defaultValue: "#9fb8db"
    }

    SliderSetting {
        settingKey: "shadowWidthPeek"

        label: "Shadow Width (Peek Mode)"
        description: "Width of the outer Dynamic Island shadow"

        defaultValue: 4

        minimum: 0
        maximum: 5

        unit: "px"
    }

    StringSetting {
        settingKey: "shadowIntensityPeek"

        label: "Shadow Intensity (Peek Mode)"
        description: "Shadow intensity from 0.0 to 0.9"

        placeholder: "0.0 - 0.9"
        defaultValue: "0.3"
    }

    ToggleSetting {
        settingKey: "interiorGlowPeek"

        label: "Interior Glow (Peek Mode)"
        description: "Enable the animated glow inside the Dynamic Island"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "innerEdgeHighlightPeek"

        label: "Inner Edge Highlight (Peek Mode)"
        description: "Enable the secondary highlight along the inner edge"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "followDmsColorSettingsPeek"

        label: "Follow DMS Color Settings (Peek Mode)"
        description: "Foloow DMS color settings for Glow/Edge color"

        defaultValue: false
    }

    SectionDivider {
        width: parent.width
        horizontalInset: 0
    }

    ColorSetting {
        settingKey: "baseColorExpanded"

        label: "Base Color (Expanded Mode)"
        description: "Base color of the Dynamic Island"

        defaultValue: "#000000"
    }

    ColorSetting {
        settingKey: "glowColorExpanded"

        label: "Glow Color (Expanded Mode)"
        description: "Color used for the interior glow and secondary highlights"

        defaultValue: "#1b3554"
    }

    ColorSetting {
        settingKey: "edgeColorExpanded"

        label: "Edge Color (Expanded Mode)"
        description: "Color used for edge highlights and specular lighting"

        defaultValue: "#9fb8db"
    }

    SliderSetting {
        settingKey: "shadowWidthExpanded"

        label: "Shadow Width (Expanded Mode)"
        description: "Width of the outer Dynamic Island shadow"

        defaultValue: 4

        minimum: 0
        maximum: 5

        unit: "px"
    }

    StringSetting {
        settingKey: "shadowIntensityExpanded"

        label: "Shadow Intensity (Expanded Mode)"
        description: "Shadow intensity from 0.0 to 0.9"

        placeholder: "0.0 - 0.9"
        defaultValue: "0.3"
    }

    ToggleSetting {
        settingKey: "interiorGlowExpanded"

        label: "Interior Glow (Expanded Mode)"
        description: "Enable the animated glow inside the Dynamic Island"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "innerEdgeHighlightExpanded"

        label: "Inner Edge Highlight (Expanded Mode)"
        description: "Enable the secondary highlight along the inner edge"

        defaultValue: true
    }

    ToggleSetting {
        settingKey: "followDmsColorSettingsExpanded"

        label: "Follow DMS Color Settings (Expanded Mode)"
        description: "Foloow DMS color settings for Glow/Edge color"

        defaultValue: false
    }
}
