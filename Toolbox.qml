import QtQuick

import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

import "components"

PluginComponent {
    id: root

    layerNamespacePlugin: "toolbox"

    property string displayText: "Toolbox"

    property bool showJavaPage: pluginData.showJavaPage !== undefined ? pluginData.showJavaPage : true
    property bool showNiriShaderPage:pluginData.showNiriShaderPage !== undefined ? pluginData.showNiriShaderPage : true

    property string selectedPage: "java"

    function isPageEnabled(page) {
        switch (page) {
            case "java":
                return showJavaPage
            case "niriShader":
                return showNiriShaderPage
            default:
                return false
        }
    }

    function firstEnabledPage() {
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

    onShowJavaPageChanged: ensureValidPage()
    onShowNiriShaderPageChanged: ensureValidPage()

    Component.onCompleted: ensureValidPage()

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "widgets"
                size: Theme.iconSize
                color: Theme.primary

                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.displayText
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText

                anchors.verticalCenter: parent.verticalCenter
            }
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
        Item {
            id: popout

            property var closePopout: null

            width: parent ? parent.width : root.popoutWidth
            implicitHeight: root.popoutHeight - Theme.spacingS * 2

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
                            if (popout.closePopout)
                                popout.closePopout()
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

                Column {
                    width: 180
                    height: parent.height

                    spacing: Theme.spacingS

                    SidebarItem {
                        width: parent.width

                        visible: root.showJavaPage

                        iconName: "coffee"
                        text: "Java Switch"

                        selected: root.selectedPage === "java"
                        onClicked: root.selectedPage = "java"
                    }

                    SidebarItem {
                        width: parent.width

                        visible: root.showNiriShaderPage

                        iconName: "animation"
                        text: "Niri Shader"

                        selected: root.selectedPage === "niriShader"
                        onClicked: root.selectedPage = "niriShader"
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
                            switch (root.selectedPage) {
                                case "java":
                                    return Qt.resolvedUrl(
                                        "pages/JavaPage.qml"
                                    )

                                case "niriShader":
                                    return Qt.resolvedUrl(
                                        "pages/NiriShaderPage.qml"
                                    )

                                default:
                                    return ""
                            }
                        }

                        onLoaded: {
                            if (item)
                                item.toolboxRoot = root
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent

                        visible: root.selectedPage === ""

                        text: "No Toolbox pages are enabled."

                        color: Theme.surfaceVariantText
                    }
                }
            }
        }
    }

    popoutWidth: 720
    popoutHeight: 480
}