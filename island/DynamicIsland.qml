import QtQuick

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property bool expanded: false

    required property real compactWidth
    required property real compactHeight

    readonly property real expandedWidth: 620
    readonly property real expandedHeight: 360

    width: expanded ? expandedWidth : compactWidth
    height: expanded ? expandedHeight : compactHeight

    radius: expanded ? 28 : compactHeight / 2
    color: Theme.surfaceContainerHighest
    clip: true

    border.width: 1
    border.color: Theme.outlineStrong

    Behavior on width {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutQuart
        }
    }

    Behavior on radius {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    Item {
        id: compactContent
        anchors.fill: parent

        opacity: root.expanded ? 0 : 1
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingS

            DankIcon {
                name: "widgets"
                size: Theme.iconSize - 2
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "Toolbox"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }
    }

    Item {
        id: expandedContent

        anchors {
            fill: parent
            margins: Theme.spacingL
        }

        opacity: root.expanded ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        Item {
            id: expandedHeader

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            height: 36

            StyledText {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                text: "Dynamic Island"
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
                    onClicked: root.expanded = false
                }
            }
        }

        StyledRect {
            anchors {
                left: parent.left
                right: parent.right
                top: expandedHeader.bottom
                bottom: parent.bottom
                topMargin: Theme.spacingM
            }

            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "widgets"
                    size: Theme.iconSize * 2
                    color: Theme.primary
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Island content goes here"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Persistent overlay surface · compact ↔ expanded"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
