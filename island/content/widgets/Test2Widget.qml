import QtQuick

import qs.Common
import qs.Widgets

import "../../core" as Core

Core.IslandWidget {
    id: root

    property date now: new Date()

    contentAvailable: true
    minimumWidthHint: Math.max(1, clockRow.implicitWidth)
    preferredWidthHint: root.minimumWidthHint
    preferredHeightHint: 36

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    Timer {
        interval: 1000
        repeat: true
        running: root.widgetVisible
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.widgetVisible
        cursorShape: Qt.PointingHandCursor

        onClicked: root.activated()
    }

    Row {
        id: clockRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        Item {
            width: Theme.spacingS
            height: 1
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "[Test2 " + Qt.formatTime(root.now, "HH:mm") + "]"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.surfaceText
        }

        Item {
            width: Theme.spacingS
            height: 1
        }
    }
}
