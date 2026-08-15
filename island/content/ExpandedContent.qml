import QtQuick

import qs.Common
import qs.Widgets

import "../core" as Core

Item {
    id: root

    property var eventData: null
    property var controller: null
    property var islandContext: null

    signal presentationRequested(string presentation)
    signal eventRequested(var event)
    signal clearRequested()

    function requestedDimension(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    readonly property real requestedWidth: root.requestedDimension(root.eventData?.payload?.width, 520)
    readonly property real requestedHeight: root.requestedDimension(root.eventData?.payload?.height, 260)

    readonly property bool wantsSplit: false
    readonly property bool animateContentChange: true
    readonly property string contentAnimation: "subtle"
    readonly property int animationRevision: 1

    readonly property url notificationSource: registry.notificationSourceFor(root.eventData)

    Core.IslandContentRegistry {
        id: registry
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

                text: String(root.eventData?.payload?.title ?? "Dynamic Island")
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
            id: payloadLoader

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                topMargin: Theme.spacingL
            }
            height: Math.max(item?.requestedHeight ?? 36, 36)

            source: root.notificationSource
            asynchronous: false

            onLoaded: {
                if (typeof item.eventData !== "undefined")
                    item.eventData = root.eventData
                if (typeof item.controller !== "undefined")
                    item.controller = root.controller
            }
        }

        StyledText {
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                topMargin: Theme.spacingL
            }

            visible: String(root.notificationSource).length === 0
            text: String(root.eventData?.payload?.message ?? root.eventData?.type ?? "Expanded content")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            wrapMode: Text.WordWrap
        }
    }

    onEventDataChanged: {
        if (payloadLoader.item && typeof payloadLoader.item.eventData !== "undefined")
            payloadLoader.item.eventData = root.eventData
    }

    onControllerChanged: {
        if (payloadLoader.item && typeof payloadLoader.item.controller !== "undefined")
            payloadLoader.item.controller = root.controller
    }

    Connections {
        target: payloadLoader.item
        ignoreUnknownSignals: true

        function onPresentationRequested(presentation) {
            root.presentationRequested(presentation)
        }

        function onEventRequested(event) {
            root.eventRequested(event)
        }
        
        function onClearRequested() {
            root.clearRequested()
        }
    }
}
