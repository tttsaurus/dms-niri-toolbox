import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property string text: ""
    property string description: ""
    property string buttonText: ""

    signal clicked()

    width: parent ? parent.width : implicitWidth
    implicitHeight: content.implicitHeight + Theme.spacingM * 2

    Row {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter

            leftMargin: Theme.spacingM
            rightMargin: Theme.spacingM
        }

        spacing: Theme.spacingM

        Column {
            width: parent.width - restartButton.width - parent.spacing
            spacing: Theme.spacingXS

            StyledText {
                width: parent.width
                text: root.text

                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }

            StyledText {
                width: parent.width
                text: root.description

                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }

        DankButton {
            id: restartButton

            anchors.verticalCenter: parent.verticalCenter

            text: root.buttonText

            onClicked: root.clicked()
        }
    }
}