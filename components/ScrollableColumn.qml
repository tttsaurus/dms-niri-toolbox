import QtQuick
import QtQuick.Controls

import qs.Common

Flickable {
    id: root

    default property alias content: contentColumn.data
    property alias spacing: contentColumn.spacing

    property real scrollSensitivity: 1.25
    property bool wheelActive: false

    readonly property bool scrollable: contentHeight > height

    clip: true

    contentWidth: width
    contentHeight: contentColumn.implicitHeight

    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds

    WheelHandler {
        target: null
        orientation: Qt.Vertical
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: event => {
            let delta

            if (event.pixelDelta.y !== 0)
                delta = event.pixelDelta.y
            else
                delta = event.angleDelta.y / 120.0 * 48.0

            const maxY = Math.max(0, root.contentHeight - root.height)

            root.contentY = Math.max(0, Math.min(maxY, root.contentY - delta * root.scrollSensitivity))

            root.wheelActive = true
            wheelActiveTimer.restart()

            event.accepted = true
        }
    }

    Timer {
        id: wheelActiveTimer

        interval: 400
        repeat: false

        onTriggered: root.wheelActive = false
    }

    ScrollBar.vertical: ScrollBar {
        id: verticalScrollBar

        width: Theme.spacingS

        policy: ScrollBar.AsNeeded
        hoverEnabled: true

        opacity: root.scrollable && (active || hovered || pressed || root.wheelActive) ? 1 : 0

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