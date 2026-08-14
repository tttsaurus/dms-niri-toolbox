import QtQuick
import QtQuick.Controls

import qs.Common

Flickable {
    id: root

    default property alias content: contentColumn.data
    property alias spacing: contentColumn.spacing

    property bool wheelActive: false
    property real scrollSensitivity: 1.5

    property real maxScrollAcceleration: 5.5
    property real scrollAcceleration: 1.0
    property real scrollSequenceStart: 0
    property real lastWheelTime: 0
    property int lastWheelDirection: 0

    property real scrollTrailResponse: 0.24
    property real maxScrollTrailDistance: 240.0

    property real wheelTargetY: 0.0
    property bool wheelAnimating: false

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

            if (delta === 0)
                return

            const now = Date.now()
            const direction = delta > 0 ? 1 : -1
            const elapsed = now - root.lastWheelTime

            const newSequence = elapsed >= 180 || direction !== root.lastWheelDirection

            if (newSequence) {
                root.scrollSequenceStart = now
                root.wheelTargetY = root.contentY
            } else if (!root.wheelAnimating) {
                root.wheelTargetY = root.contentY
            }

            const sequenceDuration = now - root.scrollSequenceStart

            root.scrollAcceleration = Math.min(root.maxScrollAcceleration, 1.0 + sequenceDuration / 650.0)

            root.lastWheelTime = now
            root.lastWheelDirection = direction

            const effectiveDelta = delta * root.scrollSensitivity * root.scrollAcceleration

            const maxY = Math.max(0, root.contentHeight - root.height)

            let targetY = root.wheelTargetY - effectiveDelta

            targetY = Math.max(root.contentY - root.maxScrollTrailDistance, Math.min(root.contentY + root.maxScrollTrailDistance,targetY))

            root.wheelTargetY = Math.max(0, Math.min(maxY, targetY))

            root.wheelAnimating = true
            root.wheelActive = true

            wheelActiveTimer.restart()
            scrollAccelerationResetTimer.restart()

            event.accepted = true
        }
    }

    Timer {
        id: wheelAnimationTimer

        interval: 16
        repeat: true
        running: root.wheelAnimating

        onTriggered: {
            const maxY = Math.max(0, root.contentHeight - root.height)

            root.wheelTargetY = Math.max(0, Math.min(maxY, root.wheelTargetY))

            const distance = root.wheelTargetY - root.contentY

            if (Math.abs(distance) <= 0.15) {
                root.contentY = root.wheelTargetY
                root.wheelAnimating = false
                return
            }

            const response = 1.0 - Math.pow(1.0 - root.scrollTrailResponse, interval / 16.6667)

            root.contentY += distance * response
        }
    }

    Timer {
        id: wheelActiveTimer

        interval: 400
        repeat: false

        onTriggered: root.wheelActive = false
    }

    Timer {
        id: scrollAccelerationResetTimer

        interval: 220
        repeat: false

        onTriggered: {
            root.scrollAcceleration = 1.0
            root.scrollSequenceStart = 0
            root.lastWheelDirection = 0
        }
    }

    onDraggingChanged: {
        if (dragging) {
            wheelAnimating = false
            wheelTargetY = contentY

            scrollAcceleration = 1.0
            scrollSequenceStart = 0
            lastWheelDirection = 0
        }
    }

    ScrollBar.vertical: ScrollBar {
        id: verticalScrollBar

        width: Theme.spacingS

        policy: ScrollBar.AsNeeded
        hoverEnabled: true

        opacity: root.scrollable && (active || hovered || pressed || root.wheelActive || root.wheelAnimating) ? 1 : 0

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