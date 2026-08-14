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

            title: "Geometry"
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
    }
}