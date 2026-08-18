import QtQuick
import Quickshell.Services.Mpris

import qs.Common
import qs.Services
import qs.Widgets

import "../../core" as Core

Core.IslandWidget {
    id: root

    property bool isSeeking: false

    readonly property MprisPlayer player: MprisController.activePlayer

    contentAvailable: root.player !== null && root.player.playbackState !== MprisPlaybackState.Stopped
    
    readonly property bool playing: root.widgetVisible && !!root.player?.isPlaying
    readonly property bool canTogglePlaying: root.widgetVisible && !!root.player?.canTogglePlaying
    readonly property bool canGoPrevious: root.widgetVisible && (!!root.player?.canGoPrevious || (!!root.player?.canSeek && root.player.position > 8))
    readonly property bool canGoNext: root.widgetVisible && !!root.player?.canGoNext
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

    minimumWidthHint: 440
    preferredWidthHint: 560
    preferredHeightHint: 230

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    function previous() {
        if (!root.canGoPrevious)
            return

        MprisController.previousOrRewind()
    }

    function togglePlaying() {
        if (!root.canTogglePlaying)
            return

        root.player.togglePlaying()
    }

    function next() {
        if (!root.canGoNext)
            return

        root.player.next()
    }

    // Kept below the actual controls. Any click not consumed by an interactive
    // child becomes the Widget's generic activation intent.
    MouseArea {
        anchors.fill: parent

        enabled: root.widgetVisible
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    Row {
        anchors.fill: parent
        anchors.margins: Theme.spacingM

        spacing: Theme.spacingL

        Item {
            id: artworkBox

            width: Math.min(168, parent.height)
            height: parent.height

            DankAlbumArt {
                anchors.centerIn: parent

                width: Math.min(parent.width, parent.height)
                height: width
                activePlayer: root.player
                albumSize: width * 0.82
                showAnimation: false
            }
        }

        Item {
            id: details

            width: Math.max(parent.width - artworkBox.width - parent.spacing, 0)
            height: parent.height

            Column {
                id: metadata

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }

                spacing: Theme.spacingXS

                StyledText {
                    width: parent.width

                    text: root.trackTitle
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    width: parent.width

                    text: root.trackArtist
                    font.pixelSize: Theme.fontSizeMedium
                    font.italic: true
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                height: 20

                MouseArea {
                    anchors.fill: parent

                    enabled: !root.player?.canSeek
                }

                DankSeekbar {
                    anchors.fill: parent

                    activePlayer: root.player
                    isSeeking: root.isSeeking

                    onIsSeekingChanged: root.isSeeking = isSeeking
                }
            }

            Row {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }

                spacing: Theme.spacingM

                Rectangle {
                    width: 40
                    height: 40
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter

                    color: previousArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    opacity: root.canGoPrevious ? 1.0 : 0.35

                    DankIcon {
                        anchors.centerIn: parent

                        name: "skip_previous"
                        size: 22
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: previousArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.previous()
                    }
                }

                Rectangle {
                    width: 48
                    height: 48
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.primary
                    opacity: root.canTogglePlaying ? 1.0 : 0.45

                    DankIcon {
                        anchors.centerIn: parent

                        name: root.playing ? "pause" : "play_arrow"
                        size: 27
                        color: Theme.primaryText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.canTogglePlaying ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.togglePlaying()
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter

                    color: nextArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    opacity: root.canGoNext ? 1.0 : 0.35

                    DankIcon {
                        anchors.centerIn: parent

                        name: "skip_next"
                        size: 22
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: nextArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.next()
                    }
                }
            }
        }
    }
}
