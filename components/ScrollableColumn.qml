import QtQuick
import QtQuick.Controls

import qs.Common

Flickable {
    id: root

    default property alias content: contentColumn.data
    property alias spacing: contentColumn.spacing

    readonly property bool scrollable: contentHeight > height

    clip: true

    contentWidth: width
    contentHeight: contentColumn.implicitHeight

    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        id: verticalScrollBar

        width: Theme.spacingS

        policy: ScrollBar.AsNeeded
        hoverEnabled: true

        opacity: root.scrollable && (active || hovered || pressed) ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 260
            }
        }

        contentItem: Rectangle {
            implicitWidth: verticalScrollBar.width

            radius: width / 2
            color: Theme.surfaceVariantText
        }

        background: Item {}
    }

    Column {
        id: contentColumn

        width: root.contentWidth
    }
}