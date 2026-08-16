import QtQuick

import qs.Common
import qs.Widgets

import "../core" as Core

Item {
    id: root

    property var notificationData: null
    property var sceneContext: ({})
    property var widgetStates: ({})
    property var islandContext: null

    signal sceneRequested(var request)
    signal widgetStatePatchRequested(string widgetId, var patch)
    signal notificationDismissRequested()
    signal clearRequested()

    readonly property string widgetId: String(root.sceneContext?.widgetId ?? root.sceneContext?.exclusiveWidgetId ?? "")
    readonly property url widgetSource: registry.widgetSourceFor(root.widgetId)
    readonly property bool hasWidget: String(root.widgetSource).length > 0 && widgetLoader.status === Loader.Ready && Boolean(widgetLoader.item?.widgetVisible ?? false)

    function hintedDimension(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    readonly property real widgetWidthHint: root.hintedDimension(widgetLoader.item?.preferredWidthHint, 360)
    readonly property real widgetHeightHint: root.hintedDimension(widgetLoader.item?.preferredHeightHint, 36)

    readonly property real requestedWidth: root.hintedDimension(root.sceneContext?.widthHint, root.hasWidget ? Math.max(420, root.widgetWidthHint + Theme.spacingL * 2) : 520)
    readonly property real requestedHeight: root.hintedDimension(root.sceneContext?.heightHint, root.hasWidget ? Math.max(180, root.widgetHeightHint + Theme.spacingL * 4) : 260)

    readonly property bool wantsSplit: false
    readonly property bool animateContentChange: true
    readonly property string contentAnimation: "subtle"
    readonly property int animationRevision: 1

    Core.IslandContentRegistry {
        id: registry
    }

    function widgetStateFor(widgetId) {
        const id = String(widgetId ?? "")
        return id.length > 0 && root.widgetStates ? (root.widgetStates[id] ?? ({})) : ({})
    }

    function syncWidgetInputs() {
        if (!widgetLoader.item)
            return

        widgetLoader.item.presentation = "expanded"
        widgetLoader.item.widgetState = root.widgetStateFor(root.widgetId)
    }

    Item {
        anchors.fill: parent
        anchors.margins: Theme.spacingL

        Item {
            id: header

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            
            height: 32

            StyledText {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                text: String(root.sceneContext?.title ?? "Dynamic Island")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            Rectangle {
                width: 30
                height: 30
                radius: 15

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                color: closeArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                DankIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: Theme.iconSize - 4
                    color: Theme.surfaceText
                }

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearRequested()
                }
            }
        }

        Loader {
            id: widgetLoader

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: parent.bottom
                topMargin: Theme.spacingL
            }

            source: root.widgetSource
            asynchronous: false
            visible: root.hasWidget

            onLoaded: root.syncWidgetInputs()
        }

        StyledText {
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                topMargin: Theme.spacingL
            }

            visible: !root.hasWidget
            text: String(root.sceneContext?.message ?? "Expanded scene")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            wrapMode: Text.WordWrap
        }
    }

    onWidgetStatesChanged: root.syncWidgetInputs()
    onSceneContextChanged: root.syncWidgetInputs()

    Connections {
        target: widgetLoader.item
        ignoreUnknownSignals: true

        function onStatePatchRequested(patch) {
            root.widgetStatePatchRequested(root.widgetId, patch)
        }
    }
}