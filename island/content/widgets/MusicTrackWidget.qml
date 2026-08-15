import QtQuick
import Quickshell.Services.Mpris

import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property string presentation: "compact"
    property var widgetState: ({})

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool widgetVisible: root.player !== null && root.player.playbackState !== MprisPlaybackState.Stopped
    readonly property bool detailed: root.presentation === "peek" || root.presentation === "expanded"
    readonly property bool playing: root.widgetVisible && !!root.player?.isPlaying
    readonly property bool canTogglePlaying: root.widgetVisible && !!root.player?.canControl
    readonly property string trackTitle: {
        const stable = String(MprisController.stableTitle || "").trim()
        if (stable.length > 0)
            return stable

        const direct = String(root.player?.trackTitle || "").trim()
        return direct.length > 0 ? direct : "Unknown track"
    }
    readonly property string trackArtist: {
        const stable = String(MprisController.stableArtist || "").trim()
        if (stable.length > 0)
            return stable

        const direct = String(root.player?.trackArtist || "").trim()
        if (direct.length > 0)
            return direct

        return String(root.player?.identity || "").trim()
    }
    readonly property url artworkSource: TrackArtService.resolvedArtUrl

    readonly property real minimumWidthHint: root.detailed ? 220 : 88
    readonly property real preferredWidthHint: root.detailed ? 310 : 104
    readonly property real preferredHeightHint: root.detailed ? 48 : 36
    readonly property bool interactive: true

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    signal activated()
    signal statePatchRequested(var patch)
    signal actionRequested(string action, var payload)

    function togglePlayback() {
        const current = root.player
        if (!current || !current.canControl)
            return

        current.togglePlaying()
        root.actionRequested("togglePlaying", {})
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.widgetVisible
        cursorShape: Qt.PointingHandCursor

        onClicked: root.activated()
    }

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        Item {
            id: artworkBox

            width: root.detailed ? 30 : 24
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 5
                color: Theme.surfaceContainerHighest
            }

            Image {
                id: artwork

                anchors.fill: parent
                source: root.artworkSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                opacity: status === Image.Ready ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            DankIcon {
                anchors.centerIn: parent
                name: "music_note"
                size: root.detailed ? 18 : 15
                color: Theme.primary
                opacity: artwork.status === Image.Ready ? 0.0 : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Item {
            id: waveBox

            width: 20
            height: root.detailed ? 24 : 18
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: [0.62, 0.92, 0.74, 1.0]

                    delegate: Rectangle {
                        width: 2.5
                        height: waveBox.height * (0.24 + index * 0.035)
                        radius: width / 2
                        color: Theme.primary

                        SequentialAnimation on height {
                            running: root.widgetVisible
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: index * 55
                            }

                            NumberAnimation {
                                to: waveBox.height * modelData
                                duration: 360 + index * 55
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: waveBox.height * (0.26 + ((index + 1) % 3) * 0.07)
                                duration: 420 + index * 45
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: metadataBox

            visible: root.detailed
            width: root.detailed ? Math.max(0, root.width - artworkBox.width - waveBox.width - playButton.width - contentRow.spacing * 3) : 0
            height: root.height
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                spacing: 1

                StyledText {
                    width: parent.width
                    text: root.trackTitle
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    width: parent.width
                    visible: root.trackArtist.length > 0
                    text: root.trackArtist
                    font.pixelSize: Math.max(9, Theme.fontSizeSmall - 2)
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        Rectangle {
            id: playButton

            width: 24
            height: 24
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.playing ? Theme.primary : Theme.surfaceContainerHighest
            opacity: root.canTogglePlaying ? 1.0 : 0.45

            DankIcon {
                anchors.centerIn: parent
                name: root.playing ? "pause" : "play_arrow"
                size: 15
                color: root.playing ? Theme.background : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.canTogglePlaying
                cursorShape: Qt.PointingHandCursor

                onClicked: root.togglePlayback()
            }
        }
    }
}