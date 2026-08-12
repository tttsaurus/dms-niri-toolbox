import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    required property var toolboxRoot

    property var closePopout: null

    width: parent ? parent.width : toolboxRoot.popoutWidth

    implicitHeight: toolboxRoot.popoutHeight - Theme.spacingS * 2

    Item {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: 64

        Column {
            anchors {
                left: parent.left
                leftMargin: Theme.spacingS

                verticalCenter: parent.verticalCenter
            }

            spacing: 2

            StyledText {
                text: "Toolbox"

                font.pixelSize: Theme.fontSizeLarge + 4

                font.weight: Font.Bold

                color: Theme.surfaceText
            }

            StyledText {
                text: "Desktop utilities"

                font.pixelSize: Theme.fontSizeSmall

                color: Theme.surfaceVariantText
            }
        }

        Rectangle {
            width: 32
            height: 32

            radius: 16

            anchors {
                right: parent.right
                rightMargin: Theme.spacingS

                verticalCenter: parent.verticalCenter
            }

            color: closeArea.containsMouse ? Theme.errorHover : "transparent"

            DankIcon {
                anchors.centerIn: parent

                name: "close"

                size: Theme.iconSize - 4

                color: closeArea.containsMouse ? Theme.error : Theme.surfaceText
            }

            MouseArea {
                id: closeArea

                anchors.fill: parent

                hoverEnabled: true

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (root.closePopout)
                        root.closePopout()
                }
            }
        }
    }

    Row {
        anchors {
            left: parent.left
            right: parent.right

            top: header.bottom
            bottom: parent.bottom

            rightMargin: Theme.spacingL
        }

        spacing: Theme.spacingM

        ScrollableColumn {
            id: menuColumn

            width: 180
            height: parent.height

            spacing: Theme.spacingS

            SidebarItem {
                width: parent.width

                visible: toolboxRoot.showSettingsPage

                iconName: "settings"
                text: "Settings"

                selected: toolboxRoot.selectedPage === "settings"
                onClicked: toolboxRoot.selectedPage = "settings"
            }

            SidebarItem {
                width: parent.width

                visible: toolboxRoot.showJavaPage

                iconName: "coffee"
                text: "Java Switch"

                selected: toolboxRoot.selectedPage === "java"
                onClicked: toolboxRoot.selectedPage = "java"
            }

            SidebarItem {
                width: parent.width

                visible: toolboxRoot.showNiriShaderPage

                iconName: "animation"
                text: "Niri Shader"

                selected: toolboxRoot.selectedPage === "niriShader"
                onClicked: toolboxRoot.selectedPage = "niriShader"
            }

            SidebarItem {
                width: parent.width

                visible: toolboxRoot.showDynamicIslandPage

                iconName: "dialogs"
                text: "Dynamic Island"

                selected: toolboxRoot.selectedPage === "dynamicIsland"
                onClicked: toolboxRoot.selectedPage = "dynamicIsland"
            }
        }

        Rectangle {
            width: 1
            height: parent.height

            color: Theme.surfaceContainerHighest
        }

        Item {
            width: parent.width - 180 - Theme.spacingM - 1
            height: parent.height

            Loader {
                id: pageLoader

                anchors.fill: parent

                source: {
                    switch (toolboxRoot.selectedPage) {
                        case "settings":
                            return Qt.resolvedUrl("../pages/SettingsPage.qml")

                        case "java":
                            return Qt.resolvedUrl("../pages/JavaPage.qml")

                        case "niriShader":
                            return Qt.resolvedUrl("../pages/NiriShaderPage.qml")

                        case "dynamicIsland":
                            return Qt.resolvedUrl("../pages/DynamicIslandPage.qml")

                        default:
                            return ""
                    }
                }

                onLoaded: {
                    if (item)
                        item.toolboxRoot = toolboxRoot
                }
            }

            StyledText {
                anchors.centerIn: parent

                visible: toolboxRoot.selectedPage === ""

                text: "No Toolbox pages are enabled."

                color: Theme.surfaceVariantText
            }
        }
    }
}