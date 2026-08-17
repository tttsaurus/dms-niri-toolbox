import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris

import qs.Common
import qs.Services
import qs.Widgets

import "../../core" as Core

Core.IslandWidget {
    id: root

    // visual host metric supplied by the composing scene
    property real hostInset: 5
    property real hostHeight: 0
    property var viewOptions: ({})

    readonly property MprisPlayer player: MprisController.activePlayer
    
    contentAvailable: root.player !== null && root.player.playbackState !== MprisPlaybackState.Stopped

    readonly property bool detailed: root.viewOptions?.showMetadata === true
    readonly property real metadataWidthLimit: {
        const limit = Number(root.viewOptions?.metadataWidthLimit ?? 0)
        return Number.isFinite(limit) && limit > 0 ? limit : 0
    }
    readonly property bool playing: root.widgetVisible && !!root.player?.isPlaying
    readonly property bool canTogglePlaying: root.widgetVisible && !!root.player?.canTogglePlaying
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

    readonly property real effectiveHostHeight: {
        const hintedHeight = Number(root.hostHeight)
        if (Number.isFinite(hintedHeight) && hintedHeight > 1)
            return hintedHeight
        return root.height > 1 ? root.height : 36
    }
    readonly property real controlInset: Math.max(3, Math.min(Number(root.hostInset) || 5, root.effectiveHostHeight * 0.24))
    readonly property real availableControlHeight: Math.max(14, root.effectiveHostHeight - root.controlInset * 2)
    readonly property real artworkSize: Math.max(14, root.availableControlHeight * 0.72)
    readonly property real artworkRadius: Math.max(4, root.artworkSize * 0.25)
    readonly property real playButtonSize: Math.max(14, root.artworkSize * 0.88)
    readonly property real playButtonVisualSize: root.playButtonSize * 1.1
    readonly property real waveHeight: Math.max(11, root.artworkSize * 0.76)
    readonly property real waveWidth: Math.max(14, root.artworkSize * 0.88)
    readonly property real controlSpacing: Math.max(4, Math.min(Theme.spacingS, root.artworkSize * 0.24))
    readonly property real metadataSpacing: root.controlSpacing
    readonly property real metadataInlineSpacing: 4
    readonly property real metadataActionSpacing: Theme.spacingL
    readonly property real leftPadding: root.detailed ? Theme.spacingS * 2 : 0
    readonly property real rightPadding: Theme.spacingS * 2
    readonly property real compactNaturalWidth: root.artworkSize + root.controlSpacing + root.waveWidth + root.controlSpacing + root.playButtonVisualSize + root.rightPadding

    readonly property real metadataTitleNaturalWidth: metadataTitleMetrics.advanceWidth
    readonly property real metadataArtistNaturalWidth: root.trackArtist.length > 0 ? metadataArtistMetrics.advanceWidth : 0
    readonly property real metadataSeparatorWidth: root.trackArtist.length > 0 ? metadataSeparatorMetrics.advanceWidth + root.metadataInlineSpacing * 2 : 0
    readonly property real metadataTextNaturalWidth: root.metadataTitleNaturalWidth + root.metadataArtistNaturalWidth
    readonly property real metadataNaturalWidth: root.metadataTextNaturalWidth + root.metadataSeparatorWidth
    readonly property real metadataPreferredWidth: root.metadataWidthLimit > 0
        ? Math.min(root.metadataWidthLimit, root.metadataNaturalWidth)
        : root.metadataNaturalWidth
    readonly property real metadataMinimumWidth: Math.min(root.metadataPreferredWidth, 92)
    readonly property real detailedFixedWidth: root.leftPadding + root.artworkSize + root.controlSpacing + root.waveWidth + root.metadataSpacing + root.metadataActionSpacing + root.playButtonVisualSize + root.rightPadding
    readonly property real metadataLayoutWidth: root.detailed ? Math.min(root.metadataPreferredWidth, Math.max(root.width - root.detailedFixedWidth, 0)) : 0
    readonly property real metadataTextWidth: Math.max(root.metadataLayoutWidth - root.metadataSeparatorWidth, 0)
    readonly property real metadataTitleWidth: root.trackArtist.length > 0 && root.metadataTextNaturalWidth > 0 ? root.metadataTextWidth * root.metadataTitleNaturalWidth / root.metadataTextNaturalWidth : root.metadataTextWidth
    readonly property real metadataArtistWidth: root.trackArtist.length > 0 ? Math.max(root.metadataTextWidth - root.metadataTitleWidth, 0) : 0

    minimumWidthHint: root.detailed ? root.detailedFixedWidth + root.metadataMinimumWidth : root.compactNaturalWidth
    preferredWidthHint: root.detailed ? root.detailedFixedWidth + root.metadataPreferredWidth : root.compactNaturalWidth
    preferredHeightHint: 36
    interactive: true

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    TextMetrics {
        id: metadataTitleMetrics
        font: metadataTitle.font
        text: root.trackTitle
    }

    TextMetrics {
        id: metadataSeparatorMetrics
        font: metadataSeparator.font
        text: metadataSeparator.text
    }

    TextMetrics {
        id: metadataArtistMetrics
        font: metadataArtist.font
        text: root.trackArtist
    }

    function togglePlayback() {
        const current = root.player
        if (!current || !current.canTogglePlaying)
            return

        current.togglePlaying()
        root.actionRequested("togglePlaying", {})
    }

    function resetWave() {
        for (let i = 0; i < waveRepeater.count; ++i) {
            const item = waveRepeater.itemAt(i)
            if (item)
                item.level = item.idleLevel
        }
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
        spacing: 0

        Item {
            visible: root.detailed
            width: root.leftPadding
            height: 1
        }

        Item {
            id: artworkBox

            width: root.artworkSize
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: root.artworkRadius
                color: Theme.surfaceContainerHighest
                antialiasing: true
            }

            Image {
                id: artworkImage

                anchors.fill: parent
                source: root.artworkSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize: Qt.size(Math.max(64, Math.round(root.artworkSize * 4)), Math.max(64, Math.round(root.artworkSize * 4)))
                visible: false
            }

            Rectangle {
                id: artworkMask

                anchors.fill: parent
                radius: root.artworkRadius
                color: "white"
                antialiasing: true
                visible: false
                layer.enabled: true
                layer.samples: 4
            }

            MultiEffect {
                anchors.fill: parent
                source: artworkImage
                maskEnabled: true
                maskSource: artworkMask
                maskThresholdMin: 0.45
                maskSpreadAtMin: 0.35
                blurEnabled: true
                blur: 0.055
                blurMax: 8
                blurMultiplier: 0.65
                autoPaddingEnabled: false
                opacity: artworkImage.status === Image.Ready ? 1.0 : 0.0
            }
        }

        Item {
            width: root.controlSpacing
            height: 1
        }

        Item {
            id: waveBox

            width: root.waveWidth
            height: root.waveHeight
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: waveRow

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }
                height: parent.height
                spacing: Math.max(1.2, root.waveWidth * 0.075)

                Repeater {
                    id: waveRepeater

                    model: [0.62, 0.92, 0.74, 1.0]

                    delegate: Item {
                        id: waveTrack

                        readonly property real idleLevel: 0.30 + index * 0.045
                        property real level: idleLevel

                        width: Math.max(1.6, root.waveWidth * 0.105)
                        height: waveBox.height

                        Rectangle {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                            }

                            width: parent.width
                            height: parent.height * waveTrack.level
                            radius: width / 2
                            color: Theme.primary
                        }

                        SequentialAnimation on level {
                            running: root.widgetVisible && root.playing
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: index * 55
                            }

                            NumberAnimation {
                                to: modelData
                                duration: 360 + index * 55
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: waveTrack.idleLevel
                                duration: 420 + index * 45
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Item {
            visible: root.detailed
            width: root.metadataSpacing
            height: 1
        }

        Item {
            id: metadataBox

            visible: root.detailed
            width: root.metadataLayoutWidth
            height: root.height
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: metadataRow

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                spacing: root.metadataInlineSpacing

                StyledText {
                    id: metadataTitle

                    anchors.verticalCenter: parent.verticalCenter

                    width: root.metadataTitleWidth
                    text: root.trackTitle
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    id: metadataSeparator

                    anchors.verticalCenter: parent.verticalCenter

                    visible: root.trackArtist.length > 0
                    text: "•"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    id: metadataArtist

                    anchors.verticalCenter: parent.verticalCenter

                    visible: root.trackArtist.length > 0
                    width: root.metadataArtistWidth
                    text: root.trackArtist
                    font.pixelSize: Theme.fontSizeMedium
                    font.italic: true
                    color: Theme.surfaceVariantText
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        Item {
            width: root.detailed ? root.metadataActionSpacing : root.controlSpacing
            height: 1
        }

        Rectangle {
            id: playButton

            width: root.playButtonVisualSize
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.playing ? Theme.primary : Theme.surfaceContainerHighest
            opacity: root.canTogglePlaying ? 1.0 : 0.45
            antialiasing: true

            DankIcon {
                anchors.centerIn: parent
                name: root.playing ? "pause" : "play_arrow"
                size: Math.max(9, root.playButtonVisualSize * 0.7)
                color: root.playing ? Theme.background : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.canTogglePlaying
                cursorShape: Qt.PointingHandCursor

                onClicked: root.togglePlayback()
            }
        }

        Item {
            width: root.rightPadding
            height: 1
        }
    }

    onPlayingChanged: {
        if (!root.playing)
            root.resetWave()
    }
}
