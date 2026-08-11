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

    property bool showSettingsPage: pluginData.showSettingsPage !== undefined ? pluginData.showSettingsPage : true
    property bool showJavaPage: pluginData.showJavaPage !== undefined ? pluginData.showJavaPage : true
    property bool showNiriShaderPage: pluginData.showNiriShaderPage !== undefined ? pluginData.showNiriShaderPage : true

    property bool dynamicIslandEnabled: pluginData.dynamicIslandEnabled !== undefined ? pluginData.dynamicIslandEnabled : true

    property string selectedPage: ""

    function isPageEnabled(page) {
        switch (page) {
            case "settings":
                return showSettingsPage
            case "java":
                return showJavaPage
            case "niriShader":
                return showNiriShaderPage
            default:
                return false
        }
    }

    function firstEnabledPage() {
        if (showSettingsPage)
            return "settings"

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

    onShowSettingsPageChanged: ensureValidPage()
    onShowJavaPageChanged: ensureValidPage()
    onShowNiriShaderPageChanged: ensureValidPage()

    function saveSetting(key, value) {
        pluginService.savePluginData(
            pluginId,
            key,
            value
        )
    }

    function publishBarAnchor(item) {
        if (!pluginService || !pluginId || !parentScreen || !item)
            return

        const screenName = parentScreen.name
        const topLeft = item.mapToItem(null, 0, 0)
        const center = item.mapToItem(
            null,
            item.width / 2,
            item.height / 2
        )

        const current = pluginService.getGlobalVar(
            pluginId,
            "barAnchorGeometry",
            {}
        )
        const next = Object.assign({}, current)

        next[screenName] = {
            edge: axis?.edge ?? "top",

            x: topLeft.x,
            y: topLeft.y,
            centerX: center.x,
            centerY: center.y,

            contentWidth: item.width,
            contentHeight: item.height,
            widgetThickness: widgetThickness,
            barThickness: blurBarWindow?.effectiveBarThickness ?? barThickness,
            barSpacing: blurBarWindow?.effectiveSpacing ?? barSpacing,
            revealed: blurBarWindow?.barRevealed ?? true
        }

        pluginService.setGlobalVar(
            pluginId,
            "barAnchorGeometry",
            next
        )
    }

    Component.onCompleted: ensureValidPage()

    horizontalBarPill: Component {
        Row {
            id: barAnchor

            spacing: Theme.spacingS

            function publish() {
                root.publishBarAnchor(barAnchor)
            }

            function publishLater() {
                Qt.callLater(publish)
            }

            Component.onCompleted: publishLater()

            onXChanged: publishLater()
            onYChanged: publishLater()
            onWidthChanged: publishLater()
            onHeightChanged: publishLater()

            Connections {
                target: root

                function onParentScreenChanged() {
                    barAnchor.publishLater()
                }

                function onBarThicknessChanged() {
                    barAnchor.publishLater()
                }

                function onWidgetThicknessChanged() {
                    barAnchor.publishLater()
                }

                function onBarConfigChanged() {
                    barAnchor.publishLater()
                }

                function onAxisChanged() {
                    barAnchor.publishLater()
                }
            }

            Connections {
                target: root.blurBarWindow

                function onEffectiveSpacingChanged() {
                    barAnchor.publish()
                }

                function onEffectiveBarThicknessChanged() {
                    barAnchor.publish()
                }

                function onBarRevealedChanged() {
                    barAnchor.publishLater()
                }
            }

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

                        visible: root.showSettingsPage

                        iconName: "settings"
                        text: "Settings"

                        selected: root.selectedPage === "settings"
                        onClicked: root.selectedPage = "settings"
                    }

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
                                case "settings":
                                    return Qt.resolvedUrl(
                                        "pages/SettingsPage.qml"
                                    )

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