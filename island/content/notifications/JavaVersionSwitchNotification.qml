import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var notificationData: null

    readonly property string displayLabel: String(root.notificationData?.payload?.label ?? "Java")

    readonly property real minimumWidthHint: 132
    readonly property real preferredWidthHint: {
        const natural = icon.width + Theme.spacingS + labelText.implicitWidth + Theme.spacingM * 2
        return Math.max(root.minimumWidthHint, natural)
    }
    readonly property real preferredHeightHint: 36
    readonly property string preferredSideHint: "right"
    readonly property string animationHint: "subtle"
    readonly property bool interactive: false

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

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