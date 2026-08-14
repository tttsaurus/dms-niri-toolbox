import QtQuick

import qs.Common
import qs.Widgets

import "../components"

Item {
    id: root

    property var toolboxRoot: null

    Column {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: Theme.spacingM

        StyledText {
            text: "Dynamic Island"

            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width

            text: "Manage the Dynamic Island settings."

            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText

            wrapMode: Text.WordWrap
        }
    }

    ScrollableColumn {
        id: settingsColumn

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom

            topMargin: Theme.spacingL
        }

        spacing: Theme.spacingM

        Foldout {
            width: parent.width

            title: "Island Geometry"
            description: "Configure the island geometry settings"

            TSliderSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "islandReservedWidth"

                text: "Island Reserved Width"
                description: "Reserved center space for Dynamic Island"

                value: root.toolboxRoot ? root.toolboxRoot.islandReservedWidth : 168

                minimum: 80
                maximum: 200

                integer: true
                unit: "px"
            }

            TSliderSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "islandCompactRadius"

                text: "Island Compact Mode Radius"
                description: "Radius for the compact Dynamic Island"

                value: root.toolboxRoot ? root.toolboxRoot.islandCompactRadius : 18

                minimum: 1
                maximum: 30

                integer: true
                unit: "px"
            }

            TSliderSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "islandPeekRadius"

                text: "Island Peek Mode Radius"
                description: "Radius for the peek Dynamic Island"

                value: root.toolboxRoot ? root.toolboxRoot.islandPeekRadius : 18

                minimum: 1
                maximum: 30

                integer: true
                unit: "px"
            }

            TSliderSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "islandExpandedRadius"

                text: "Island Expanded Mode Radius"
                description: "Radius for the expanded Dynamic Island"

                value: root.toolboxRoot ? root.toolboxRoot.islandExpandedRadius : 128

                minimum: 10
                maximum: 300

                integer: true
                unit: "px"
            }
        }

        Foldout {
            width: parent.width

            title: "Island Shader (Compact)"
            description: "Configure the island shader settings (compact mode)"

            TColorSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "baseColorCompact"

                text: "Base Color (Compact Mode)"
                description: "Base color of the Dynamic Island"

                value: root.toolboxRoot ? root.toolboxRoot.baseColorCompact : "#000000"
            }

            TColorSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "glowColorCompact"

                text: "Glow Color (Compact Mode)"
                description: "Color used for the interior glow and secondary highlights"

                value: root.toolboxRoot ? root.toolboxRoot.glowColorCompact : "#1b3554"
            }

            TColorSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "edgeColorCompact"

                text: "Edge Color (Compact Mode)"
                description: "Color used for edge highlights and specular lighting"

                value: root.toolboxRoot ? root.toolboxRoot.edgeColorCompact : "#9fb8db"
            }

            TSliderSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "shadowWidthCompact"

                text: "Shadow Width (Compact Mode)"
                description: "Width of the outer Dynamic Island shadow"

                value: root.toolboxRoot ? root.toolboxRoot.shadowWidthCompact : 4

                minimum: 0
                maximum: 5

                integer: true
                unit: "px"
            }

            TFloatSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "shadowIntensityCompact"

                text: "Shadow Intensity (Compact Mode)"
                description: "Shadow intensity from 0.0 to 0.9"

                value: root.toolboxRoot ? root.toolboxRoot.shadowIntensityCompact : 0.3

                minimum: 0.0
                maximum: 0.9

                placeholder: "0.0 - 0.9"
            }

            TToggleSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "interiorGlowCompact"

                text: "Interior Glow (Compact Mode)"
                description: "Enable the animated glow inside the Dynamic Island"

                checked: root.toolboxRoot ? root.toolboxRoot.interiorGlowCompact : true
            }

            TToggleSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "innerEdgeHighlightCompact"

                text: "Inner Edge Highlight (Compact Mode)"
                description: "Enable the secondary highlight along the inner edge"

                checked: root.toolboxRoot ? root.toolboxRoot.innerEdgeHighlightCompact : true
            }

            TToggleSetting {
                toolboxRoot: root.toolboxRoot
                settingKey: "followDmsColorSettingsCompact"

                text: "Follow DMS Color Settings (Compact Mode)"
                description: "Foloow DMS color settings for Base/Glow/Edge color"

                checked: root.toolboxRoot ? root.toolboxRoot.followDmsColorSettingsCompact : false
            }
        }

        Foldout {
            width: parent.width

            title: "Island Shader (Peek)"
            description: "Configure the island shader settings (peek mode)"
        }

        Foldout {
            width: parent.width

            title: "Island Shader (Expanded)"
            description: "Configure the island shader settings (expanded mode)"
        }
    }
}