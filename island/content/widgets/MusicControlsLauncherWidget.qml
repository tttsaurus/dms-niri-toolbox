import QtQuick

import qs.Common
import qs.Widgets

import "../../core" as Core

Core.IslandWidget {
    id: root

    contentAvailable: true
    minimumWidthHint: 16
    preferredWidthHint: root.minimumWidthHint
    preferredHeightHint: 36

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    DankIcon {
        anchors.centerIn: parent

        name: "music_note"
        size: Math.min(16, Math.max(1, Math.min(root.width, root.height)))
        color: Theme.primary
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
