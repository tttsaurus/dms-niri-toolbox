import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property string presentation: "compact"
    property var widgetState: ({})
    property date now: new Date()

    readonly property real minimumWidthHint: 52
    readonly property real preferredWidthHint: Math.max(root.minimumWidthHint, clockText.implicitWidth)
    readonly property real preferredHeightHint: 36
    readonly property bool interactive: false

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

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