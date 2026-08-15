import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property date now: new Date()

    readonly property real requestedWidth: Math.max(52, clockText.implicitWidth)
    readonly property real requestedHeight: 36

    implicitWidth: requestedWidth
    implicitHeight: requestedHeight

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    StyledText {
        id: clockText
        anchors.centerIn: parent

        text: Qt.formatTime(root.now, "HH:mm")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }
}
