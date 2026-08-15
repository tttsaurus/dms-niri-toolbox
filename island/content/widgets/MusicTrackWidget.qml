import QtQuick

import qs.Common
import qs.Widgets

Item {
    id: root

    property string presentation: "compact"
    property var widgetState: ({})

    readonly property bool paused: widgetState?.paused ?? false
    readonly property real minimumWidthHint: root.presentation === "compact" ? 102 : 220
    readonly property real preferredWidthHint: {
        switch (root.presentation) {
            case "expanded":
                return 360
            case "peek":
                return 300
            default:
                return 118
        }
    }
    readonly property real preferredHeightHint: 36
    readonly property bool interactive: true

    signal activated()
    signal statePatchRequested(var patch)
    signal actionRequested(string action, var payload)

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    Row {
        id: trackRow

        anchors {
            fill: parent
            leftMargin: Theme.spacingS
            rightMargin: Theme.spacingS
        }
        spacing: Theme.spacingS

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "album"
            size: Theme.iconSize - 3
            color: Theme.primary
        }

        Row {
            id: volumeBars

            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 16
            spacing: 2

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    anchors.bottom: parent.bottom
                    property real animatedHeight: 6 + index * 3

                    width: 4
                    height: root.paused ? 4 : animatedHeight
                    radius: width / 2
                    color: Theme.surfaceText

                    SequentialAnimation on animatedHeight {
                        running: root.visible && !root.paused
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 14 - index * 2
                            duration: 220 + index * 70
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 5 + index * 2
                            duration: 260 + index * 60
                            easing.type: Easing.InOutSine
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Item {
            id: detailsSlot

            visible: root.presentation !== "compact"
            width: visible ? (root.presentation === "expanded" ? 170 : 110) : 0
            height: parent.height
        }

        Rectangle {
            id: pauseButton

            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: 12
            color: pauseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"

            DankIcon {
                anchors.centerIn: parent
                name: root.paused ? "play_arrow" : "pause"
                size: Theme.iconSize - 6
                color: Theme.surfaceText
            }

            MouseArea {
                id: pauseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const nextPaused = !root.paused
                    root.statePatchRequested({ paused: nextPaused })
                    root.actionRequested(nextPaused ? "pause" : "resume", {})
                }
            }
        }
    }
}