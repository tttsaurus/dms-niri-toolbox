import QtQuick
import QtQuick.Controls

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

    Flickable {
        id: settingsFlickable

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom

            topMargin: Theme.spacingL
        }

        clip: true

        contentWidth: width
        contentHeight: settingsColumn.implicitHeight

        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: verticalScrollBar

            width: Theme.spacingS

            policy: ScrollBar.AsNeeded
            hoverEnabled: true

            opacity: active || hovered || pressed ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                }
            }

            contentItem: Rectangle {
                implicitWidth: verticalScrollBar.width
                radius: width / 2
                color: Theme.surfaceVariantText
            }

            background: Item {}
        }

        Column {
            id: settingsColumn

            width: settingsFlickable.width
            spacing: Theme.spacingM

            StyledRect {
                width: parent.width
                height: dynamicIslandGroup.implicitHeight

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    id: dynamicIslandGroup

                    width: parent.width

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
                }
            }
        }
    }
}