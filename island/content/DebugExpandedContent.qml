import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var eventData: null
    property var controller: null

    function requestedDimension(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    readonly property real requestedWidth: root.requestedDimension(
        root.eventData?.payload?.width,
        520
    )

    readonly property real requestedHeight: root.requestedDimension(
        root.eventData?.payload?.height,
        260
    )

    Item {
        anchors {
            fill: parent
            margins: Theme.spacingL
        }

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

                text: "Island Debug"
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

                    onClicked: {
                        if (root.controller)
                            root.controller.clear()
                    }
                }
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                topMargin: Theme.spacingL
            }

            spacing: Theme.spacingS

            StyledText {
                width: parent.width
                text: root.eventData?.payload?.message ?? "Debug expanded content"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }

            StyledText {
                width: parent.width
                text: "Requested size: "
                    + Math.round(root.requestedWidth)
                    + " × "
                    + Math.round(root.requestedHeight)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width
                text: "This size is requested by DebugExpandedContent.qml, not by DynamicIsland.qml."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }
}
