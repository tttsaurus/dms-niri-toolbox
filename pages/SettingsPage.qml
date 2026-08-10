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
            text: "Settings"

            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width

            text: "Manage Toolbox settings."

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

                text: "Settings controls will go here"
                color: Theme.surfaceVariantText
            }
        }
    }
}