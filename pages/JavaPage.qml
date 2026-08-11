import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var toolboxRoot: null

    Column {
        id: header
        
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: Theme.spacingM

        StyledText {
            text: "Java Switch"

            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width

            text: "Switch the active Java development environment."

            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText

            wrapMode: Text.WordWrap
        }

        StyledRect {
            width: parent.width
            height: 96

            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                anchors.centerIn: parent

                text: "Java controls will go here"
                color: Theme.surfaceVariantText
            }
        }
    }
}