import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var eventData: null
    property var controller: null

    readonly property string displayLabel: String(root.eventData?.payload?.label ?? "Java")

    readonly property real requestedWidth: {
        const override = Number(root.eventData?.payload?.width)
        if (Number.isFinite(override) && override > 0)
            return Math.max(112, Math.min(300, override))

        const natural = icon.width + Theme.spacingS + labelText.implicitWidth + Theme.spacingM * 2
        return Math.max(132, Math.min(260, natural))
    }
    readonly property real requestedHeight: 36
    readonly property string preferredSide: "right"
    readonly property bool interactive: false

    signal presentationRequested(string presentation)
    signal eventRequested(var event)
    signal clearRequested()

    implicitWidth: requestedWidth
    implicitHeight: requestedHeight

    Row {
        id: contentRow

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.spacingM
            rightMargin: Theme.spacingM
        }
        spacing: Theme.spacingS

        DankIcon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter

            name: "coffee"
            size: Theme.iconSize - 3
            color: Theme.primary
        }

        StyledText {
            id: labelText
            anchors.verticalCenter: parent.verticalCenter

            width: Math.max(0, contentRow.width - icon.width - contentRow.spacing)
            text: "Java → " + root.displayLabel

            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText

            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
