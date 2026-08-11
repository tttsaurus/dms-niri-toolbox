import QtQuick

import qs.Common
import qs.Widgets

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

            text: "Manage Toolbox settings."

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
                height: 80

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Row {
                    anchors {
                        fill: parent
                        leftMargin: Theme.spacingM
                        rightMargin: Theme.spacingM
                    }

                    spacing: Theme.spacingM

                    Column {
                        width: parent.width - javaToggle.width - Theme.spacingM

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: Theme.spacingXS

                        StyledText {
                            width: parent.width

                            text: "Java Switch"

                            font.pixelSize: Theme.fontSizeMedium

                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            width: parent.width

                            text: "Show the Java environment switcher in Toolbox"

                            font.pixelSize: Theme.fontSizeSmall

                            color: Theme.surfaceVariantText

                            wrapMode: Text.WordWrap
                        }
                    }

                    DankToggle {
                        id: javaToggle

                        anchors.verticalCenter: parent.verticalCenter

                        checked: toolboxRoot ? toolboxRoot.showJavaPage : true

                        onToggled: isChecked => {
                            if (!toolboxRoot)
                                return

                            toolboxRoot.saveSetting("showJavaPage", isChecked)
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: 80

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Row {
                    anchors {
                        fill: parent
                        leftMargin: Theme.spacingM
                        rightMargin: Theme.spacingM
                    }

                    spacing: Theme.spacingM

                    Column {
                        width: parent.width - niriShaderToggle.width - Theme.spacingM

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: Theme.spacingXS

                        StyledText {
                            width: parent.width

                            text: "Niri Shader"

                            font.pixelSize: Theme.fontSizeMedium

                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            width: parent.width

                            text: "Show the Niri shader manager in Toolbox"

                            font.pixelSize: Theme.fontSizeSmall

                            color: Theme.surfaceVariantText

                            wrapMode: Text.WordWrap
                        }
                    }

                    DankToggle {
                        id: niriShaderToggle

                        anchors.verticalCenter: parent.verticalCenter

                        checked: toolboxRoot ? toolboxRoot.showNiriShaderPage : true

                        onToggled: isChecked => {
                            if (!toolboxRoot)
                                return

                            toolboxRoot.saveSetting("showNiriShaderPage", isChecked)
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: 80

                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Row {
                    anchors {
                        fill: parent
                        leftMargin: Theme.spacingM
                        rightMargin: Theme.spacingM
                    }

                    spacing: Theme.spacingM

                    Column {
                        width: parent.width - dynamicIslandToggle.width - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        StyledText {
                            width: parent.width
                            text: "Dynamic Island"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            width: parent.width
                            text: "Show the top-center Dynamic Island overlay"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                        }
                    }

                    DankToggle {
                        id: dynamicIslandToggle
                        anchors.verticalCenter: parent.verticalCenter

                        checked: toolboxRoot ? toolboxRoot.dynamicIslandEnabled : true
                        onToggled: isChecked => {
                            if (!toolboxRoot)
                                return

                            toolboxRoot.saveSetting("dynamicIslandEnabled", isChecked)
                        }
                    }
                }
            }

        }
    }
}