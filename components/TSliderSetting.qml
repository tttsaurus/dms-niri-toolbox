import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    required property var toolboxRoot
    required property string settingKey

    property string text: ""
    property string description: ""

    property real value: 0
    property real minimum: 0
    property real maximum: 100

    property string unit: ""
    property string leftIcon: ""
    property string rightIcon: ""

    property bool integer: false

    property real horizontalPadding: Theme.spacingM
    property real verticalPadding: Theme.spacingM

    implicitHeight: content.implicitHeight + verticalPadding * 2
    width: parent ? parent.width : implicitWidth

    function normalizeValue(value) {
        const number = Number(value)

        if (!Number.isFinite(number))
            return root.value

        const clamped = Math.max(root.minimum, Math.min(root.maximum, number))

        return root.integer ? Math.floor(clamped) : clamped
    }

    Column {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
        }

        spacing: Theme.spacingS

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

        DankSlider {
            width: parent.width

            value: root.value
            minimum: root.minimum
            maximum: root.maximum

            unit: root.unit
            leftIcon: root.leftIcon
            rightIcon: root.rightIcon

            wheelEnabled: false

            thumbOutlineColor: Theme.withAlpha(Theme.surfaceContainerHighest, Theme.popupTransparency)

            onSliderValueChanged: newValue => {
                if (!root.toolboxRoot)
                    return

                root.toolboxRoot.saveSetting(
                    root.settingKey,
                    root.normalizeValue(newValue)
                )
            }
        }
    }
}