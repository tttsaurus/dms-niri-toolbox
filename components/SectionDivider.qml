import QtQuick

import qs.Common

Item {
    id: root

    property real horizontalInset: Theme.spacingM
    property real dividerHeight: 1

    property color dividerColor: Theme.withAlpha(Theme.surfaceVariantText, 0.25)

    implicitHeight: dividerHeight

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.horizontalInset
            rightMargin: root.horizontalInset
            verticalCenter: parent.verticalCenter
        }

        height: root.dividerHeight
        color: root.dividerColor
    }
}