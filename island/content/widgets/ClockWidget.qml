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
    interactive: false

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    readonly property string dateText: {
        const text = Qt.formatDate(root.now, "ddd d").toLowerCase()
        return text.charAt(0).toUpperCase() + text.slice(1)
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.widgetVisible
        triggeredOnStart: true
        onTriggered: root.now = new Date()
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
            text: Qt.formatTime(root.now, "HH:mm")
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "•"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.surfaceText
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: dateText
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            font.italic: true
            color: Theme.surfaceVariantText
        }

        Item {
            width: Theme.spacingS
            height: 1
        }
    }
}
