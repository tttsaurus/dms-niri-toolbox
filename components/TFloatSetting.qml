import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    required property var toolboxRoot
    required property string settingKey

    property string text: ""
    property string description: ""

    property real value: 0.0

    property real minimum: -Infinity
    property real maximum: Infinity

    property string placeholder: ""

    property real horizontalPadding: Theme.spacingM

    implicitHeight: 76
    width: parent ? parent.width : implicitWidth

    function syncText() {
        if (!valueField.activeFocus)
            valueField.text = root.value.toString()
    }

    function commit() {
        if (!root.toolboxRoot)
            return

        const parsed = Number(valueField.text)

        if (!Number.isFinite(parsed)) {
            syncText()
            return
        }

        const clamped = Math.max(root.minimum, Math.min(root.maximum, parsed))
        const serialized = clamped.toString()

        valueField.text = serialized

        root.toolboxRoot.saveSetting(
            root.settingKey,
            serialized
        )
    }

    onValueChanged: syncText()

    Component.onCompleted: syncText()

    Row {
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        spacing: Theme.spacingM

        Column {
            width: parent.width - valueField.width - Theme.spacingM

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

        DankTextField {
            id: valueField

            width: 100

            anchors.verticalCenter: parent.verticalCenter

            placeholderText: root.placeholder

            onAccepted: {
                root.commit()
                root.forceActiveFocus()
            }

            onActiveFocusChanged: {
                if (!activeFocus)
                    root.commit()
            }
        }
    }
}