import QtQuick

import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    required property var toolboxRoot
    required property string settingKey

    property string text: ""
    property string description: ""

    property color value: Theme.primary

    property real horizontalPadding: Theme.spacingM

    implicitHeight: 76
    width: parent ? parent.width : implicitWidth

    Item {
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        Rectangle {
            id: colorPreview

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            width: 48
            height: 36

            radius: Theme.cornerRadius
            color: root.value

            border {
                color: Theme.outlineStrong
                width: 2
            }

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (!root.toolboxRoot || !PopoutService || !PopoutService.colorPickerModal)
                        return

                    PopoutService.colorPickerModal.selectedColor = root.value
                    PopoutService.colorPickerModal.pickerTitle = root.text

                    PopoutService.colorPickerModal.onColorSelectedCallback = function(selectedColor) {
                        root.toolboxRoot.saveSetting(
                            root.settingKey,
                            selectedColor.toString()
                        )
                    }

                    PopoutService.colorPickerModal.show()
                }
            }
        }

        StyledText {
            id: colorText

            anchors {
                right: colorPreview.left
                rightMargin: Theme.spacingS
                verticalCenter: parent.verticalCenter
            }

            width: 72

            text: root.value.toString()

            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText

            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Column {
            anchors {
                left: parent.left
                right: colorText.left
                rightMargin: Theme.spacingM
                verticalCenter: parent.verticalCenter
            }

            spacing: Theme.spacingXS

            StyledText {
                width: parent.width

                text: root.text

                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText

                elide: Text.ElideRight
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
    }
}