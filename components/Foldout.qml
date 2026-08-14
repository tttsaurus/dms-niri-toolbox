import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    default property alias content: contentColumn.data
    property alias spacing: contentColumn.spacing

    property string title: ""
    property string description: ""

    property bool expanded: false

    property color color: Theme.surfaceContainerHigh
    property color headerColor: "transparent"

    signal toggled(bool expanded)

    width: parent ? parent.width : implicitWidth
    height: container.height

    StyledRect {
        id: container

        width: parent.width
        height: header.height + contentWrapper.height

        radius: Theme.cornerRadius
        color: root.color

        clip: true

        Rectangle {
            id: header

            width: parent.width
            height: Math.max(52, headerText.implicitHeight + Theme.spacingM * 2)

            color: root.headerColor

            Column {
                id: headerText

                anchors {
                    left: parent.left
                    right: indicator.left
                    verticalCenter: parent.verticalCenter

                    leftMargin: Theme.spacingM
                    rightMargin: Theme.spacingM
                }

                spacing: 2

                StyledText {
                    width: parent.width

                    text: root.title

                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    width: parent.width

                    visible: root.description.length > 0
                    height: visible ? implicitHeight : 0

                    text: root.description

                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText

                    wrapMode: Text.WordWrap
                }
            }

            StyledText {
                id: indicator

                anchors {
                    right: parent.right
                    rightMargin: Theme.spacingM
                    verticalCenter: parent.verticalCenter
                }

                text: "⌄"

                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText

                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.expanded = !root.expanded
                    root.toggled(root.expanded)
                }
            }
        }

        Rectangle {
            id: divider

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
            }

            height: root.expanded ? 1 : 0
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.25)

            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
        }

        Item {
            id: contentWrapper

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
            }

            height: root.expanded ? contentColumn.implicitHeight : 0

            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                id: contentColumn

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }

                spacing: Theme.spacingS

                enabled: root.expanded

                opacity: root.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                    }
                }
            }
        }
    }
}