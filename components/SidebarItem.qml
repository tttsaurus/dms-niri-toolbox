import QtQuick

import qs.Common
import qs.Widgets

StyledRect {
    id: root

    property string iconName: ""
    property string text: ""
    property bool selected: false

    signal clicked()

    height: 48
    radius: Theme.cornerRadius

    color: selected ? Theme.surfaceContainerHighest : "transparent"

    Row {
        anchors.fill: parent

        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM

        spacing: Theme.spacingM

        DankIcon {
            name: root.iconName
            size: Theme.iconSize

            color: root.selected ? Theme.primary : Theme.surfaceVariantText

            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.text

            color: root.selected ? Theme.surfaceText : Theme.surfaceVariantText

            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}