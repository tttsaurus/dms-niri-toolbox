import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var eventData: null
    property var controller: null

    // the presenter ignores these while in compact mode
    // but keeping the content contract uniform makes content interchangeable
    readonly property real requestedWidth: 168
    readonly property real requestedHeight: 36

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacingS

        DankIcon {
            name: "widgets"
            size: Theme.iconSize - 2
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: "Toolbox"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        // placeholder interaction
        onClicked: {
            if (!root.controller)
                return

            root.controller.push({
                type: "debugExpanded",
                presentation: "expanded",
                payload: {
                    message: "Opened from compact island",
                    width: 520,
                    height: 260
                }
            })
        }
    }
}
