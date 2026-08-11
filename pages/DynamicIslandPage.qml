import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var toolboxRoot: null

    Column {
        anchors.fill: parent
        spacing: Theme.spacingM

        StyledText {
            text: "Dynamic Island"

            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width

            text: "Manage the Dynamic Island settings."

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

                text: "Dynamic Island controls will go here"
                color: Theme.surfaceVariantText
            }
        }
    }
}