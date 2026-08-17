import QtQuick

import qs.Common
import qs.Widgets

import "../core" as Core
import "components" as Content

Item {
    id: root

    property var notificationData: null
    property var sceneContext: ({})
    property var widgetStates: ({})
    property var islandContext: null

    signal accessRequested(var request)
    signal sceneRequested(var request)
    signal widgetStatePatchRequested(string widgetId, var patch)
    signal notificationDismissRequested()
    signal dismissRequested()
    signal clearRequested()

    readonly property string widgetId: String(root.sceneContext?.widgetId ?? root.sceneContext?.exclusiveWidgetId ?? "")
    readonly property var presentationSpec: registry.presentationSpecFor(root.widgetId, "expanded")
    readonly property bool hasWidget: expandedWidgetHost.widgetReady && expandedWidgetHost.widgetVisible
    readonly property bool backOnWidgetActivation: root.sceneContext?.backOnWidgetActivation === true
    readonly property bool backWhenWidgetUnavailable: root.sceneContext?.backWhenWidgetUnavailable === true || root.presentationSpec.backWhenUnavailable === true
    readonly property string title: String(root.sceneContext?.title ?? root.presentationSpec.title ?? "Dynamic Island")

    property bool _backPending: false

    function hintedDimension(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    function widgetStateFor(widgetId) {
        const id = String(widgetId ?? "")
        return id.length > 0 && root.widgetStates ? (root.widgetStates[id] ?? ({})) : ({})
    }

    readonly property real widgetWidthHint: root.hintedDimension(expandedWidgetHost.preferredWidthHint, 360)
    readonly property real widgetHeightHint: root.hintedDimension(expandedWidgetHost.preferredHeightHint, 36)

    readonly property real requestedWidth: root.hintedDimension(root.sceneContext?.widthHint,root.hasWidget ? Math.max(420, root.widgetWidthHint + Theme.spacingL * 2) : 520)
    readonly property real requestedHeight: root.hintedDimension(root.sceneContext?.heightHint, root.hasWidget ? Math.max(180, root.widgetHeightHint + Theme.spacingL * 4) : 260)

    readonly property bool wantsSplit: false
    readonly property bool animateContentChange: true
    readonly property string contentAnimation: "subtle"
    readonly property int animationRevision: Number(root.sceneContext?.accessId ?? 1)

    Core.IslandContentRegistry {
        id: registry
    }

    function requestBack() {
        if (root._backPending)
            return

        root._backPending = true
        root.accessRequested({ navigation: "back" })
    }

    function activateWidget() {
        const request = registry.activationRequestFor(root.widgetId, "expanded")
        if (request) {
            root.accessRequested(request)
            return
        }

        if (root.backOnWidgetActivation)
            root.requestBack()
    }

    function reconcileWidgetAvailability() {
        if (!root.backWhenWidgetUnavailable
                || !expandedWidgetHost.widgetReady
                || expandedWidgetHost.widgetVisible) return

        Qt.callLater(root.requestBack)
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

                text: root.title
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
                    onClicked: root.dismissRequested()
                }
            }
        }

        Content.IslandWidgetHost {
            id: expandedWidgetHost

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: parent.bottom
                topMargin: Theme.spacingL
            }

            registry: registry
            widgetId: root.widgetId
            presentation: "expanded"
            widgetState: root.widgetStateFor(root.widgetId)
            scaleWithVisibility: false

            onActivated: root.activateWidget()
            onStatePatchRequested: patch => root.widgetStatePatchRequested(root.widgetId, patch)
            onAccessRequested: request => root.accessRequested(Object.assign({}, request))
            onWidgetReadyChanged: root.reconcileWidgetAvailability()
            onWidgetVisibleChanged: root.reconcileWidgetAvailability()
        }

        StyledText {
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                topMargin: Theme.spacingL
            }

            visible: !root.hasWidget
            text: String(root.sceneContext?.message ?? "Expanded Widget is unavailable")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            wrapMode: Text.WordWrap
        }
    }

    onSceneContextChanged: {
        root._backPending = false
        Qt.callLater(root.reconcileWidgetAvailability)
    }

    Component.onCompleted: Qt.callLater(root.reconcileWidgetAvailability)
}
