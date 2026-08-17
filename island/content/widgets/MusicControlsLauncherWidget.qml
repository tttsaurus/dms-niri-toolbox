import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property string presentation: "peek"
    property var widgetState: ({})

    readonly property bool widgetVisible: true
    readonly property real minimumWidthHint: 16
    readonly property real preferredWidthHint: root.minimumWidthHint
    readonly property real preferredHeightHint: 36
    readonly property bool interactive: true

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    signal activated()
    signal statePatchRequested(var patch)
    signal actionRequested(string action, var payload)

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
