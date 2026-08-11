import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    required property var toolboxRoot
    required property string settingKey

    property string text: ""
    property string description: ""

    property bool checked: false

    property real horizontalPadding: Theme.spacingM

    implicitHeight: 76
    width: parent ? parent.width : implicitWidth

    Row {
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        spacing: Theme.spacingM

        Column {
            width: parent.width - toggle.width - Theme.spacingM

            anchors.verticalCenter: parent.verticalCenter

            spacing: Theme.spacingXS

            StyledText {
                width: parent.width

                text: root.text

                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                width: parent.width

                visible: root.description.length > 0

                text: root.description

                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText

                wrapMode: Text.WordWrap
            }
        }

        DankToggle {
            id: toggle

            anchors.verticalCenter: parent.verticalCenter

            checked: root.checked

            onToggled: isChecked => {
                if (!root.toolboxRoot)
                    return

                root.toolboxRoot.saveSetting(
                    root.settingKey,
                    isChecked
                )
            }
        }
    }
}