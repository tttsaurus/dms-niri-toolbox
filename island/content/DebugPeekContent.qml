import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property var eventData: null
    property var controller: null

    readonly property real requestedWidth: {
        const value = Number(root.eventData?.payload?.width ?? 280)
        return Number.isFinite(value) ? value : 280
    }

    // peek deliberately remains at the DankBar height
    // and the presenter ignores this request unless the event is promoted to expanded mode
    readonly property real requestedHeight: 36

    Row {
        anchors {
            fill: parent
            leftMargin: Theme.spacingM
            rightMargin: Theme.spacingM
        }

        spacing: Theme.spacingS

        DankIcon {
            name: "terminal"
            size: Theme.iconSize - 2
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            width: parent.width - Theme.iconSize - Theme.spacingS * 2
            anchors.verticalCenter: parent.verticalCenter

            text: root.eventData?.payload?.message ?? "Debug peek"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!root.controller)
                return

            root.controller.push({
                type: "debugExpanded",
                presentation: "expanded",
                payload: {
                    message: root.eventData?.payload?.message ?? "Promoted debug peek",
                    width: 520,
                    height: 260
                }
            })
        }
    }
}
