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
            text: "Settings"

            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width

            text: "Manage Toolbox settings. Goto DMS \"Settings -> Plugins\" for more configs."

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

        Column {
            id: settingsColumn

            width: settingsFlickable.width
            spacing: Theme.spacingM

            StyledRect {
                width: parent.width
                height: javaGroup.implicitHeight

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    id: javaGroup

                    width: parent.width

                    TToggleSetting {
                        width: parent.width

                        toolboxRoot: root.toolboxRoot
                        settingKey: "showJavaPage"

                        text: "Java Switch"
                        description: "Show the Java environment switcher in Toolbox"

                        checked: root.toolboxRoot ? root.toolboxRoot.showJavaPage : true
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: niriShaderGroup.implicitHeight

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    id: niriShaderGroup

                    width: parent.width

                    TToggleSetting {
                        width: parent.width

                        toolboxRoot: root.toolboxRoot
                        settingKey: "showNiriShaderPage"

                        text: "Niri Shader"
                        description: "Show the Niri shader manager in Toolbox"

                        checked: root.toolboxRoot ? root.toolboxRoot.showNiriShaderPage : true
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: dynamicIslandGroup.implicitHeight

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    id: dynamicIslandGroup

                    width: parent.width

                    TToggleSetting {
                        width: parent.width

                        toolboxRoot: root.toolboxRoot
                        settingKey: "dynamicIslandEnabled"

                        text: "Dynamic Island Overlay"
                        description: "Show the top-center Dynamic Island overlay"

                        checked: root.toolboxRoot ? root.toolboxRoot.dynamicIslandEnabled : true
                    }

                    TToggleSetting {
                        width: parent.width

                        toolboxRoot: root.toolboxRoot
                        settingKey: "showDynamicIslandPage"

                        text: "Dynamic Island"
                        description: "Show the Dynamic Island settings page"

                        checked: root.toolboxRoot ? root.toolboxRoot.showDynamicIslandPage : true
                    }
                }
            }
        }
    }
}