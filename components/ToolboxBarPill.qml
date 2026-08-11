import QtQuick

import qs.Common
import qs.Widgets

Row {
    id: root

    required property var toolboxRoot

    spacing: Theme.spacingS

    function publish() {
        const toolbox = root.toolboxRoot

        if (!toolbox.pluginService || !toolbox.pluginId || !toolbox.parentScreen)
            return

        const screenName = toolbox.parentScreen.name
        const topLeft = root.mapToItem(null, 0, 0)
        const center = root.mapToItem(null, root.width / 2, root.height / 2)
        
        const current = toolbox.pluginService.getGlobalVar(
            toolbox.pluginId,
            "barAnchorGeometry",
            {}
        )
        const next = Object.assign({}, current)

        next[screenName] = {
            edge: toolbox.axis?.edge ?? "top",

            x: topLeft.x,
            y: topLeft.y,

            centerX: center.x,
            centerY: center.y,

            contentWidth: root.width,
            contentHeight: root.height,

            widgetThickness: toolbox.widgetThickness,

            barThickness: toolbox.blurBarWindow ?.effectiveBarThickness ?? toolbox.barThickness,
            barSpacing: toolbox.blurBarWindow ?.effectiveSpacing ?? toolbox.barSpacing,
            revealed: toolbox.blurBarWindow ?.barRevealed ?? true
        }

        toolbox.pluginService.setGlobalVar(
            toolbox.pluginId,
            "barAnchorGeometry",
            next
        )
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
        target: root.toolboxRoot

        function onParentScreenChanged() {
            root.publishLater()
        }

        function onBarThicknessChanged() {
            root.publishLater()
        }

        function onWidgetThicknessChanged() {
            root.publishLater()
        }

        function onBarConfigChanged() {
            root.publishLater()
        }

        function onAxisChanged() {
            root.publishLater()
        }
    }

    Connections {
        target: root.toolboxRoot.blurBarWindow

        function onEffectiveSpacingChanged() {
            root.publish()
        }

        function onEffectiveBarThicknessChanged() {
            root.publish()
        }

        function onBarRevealedChanged() {
            root.publishLater()
        }
    }

    DankIcon {
        name: "widgets"

        size: Theme.iconSize
        color: Theme.primary

        anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
        text: root.toolboxRoot.displayText

        font.pixelSize: Theme.fontSizeMedium

        color: Theme.surfaceText

        anchors.verticalCenter: parent.verticalCenter
    }
}