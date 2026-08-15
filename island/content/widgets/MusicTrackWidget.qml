import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris

import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property string presentation: "compact"
    property var widgetState: ({})
    // visual host metric supplied by the composing scene
    property real hostInset: 5

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

    readonly property real effectiveHostHeight: root.height > 1 ? root.height : 36
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
    readonly property real leftPadding: root.detailed ? Theme.spacingS * 2 : 0
    readonly property real rightPadding: Theme.spacingS * 2
    readonly property real compactNaturalWidth: root.artworkSize + root.waveWidth + root.playButtonVisualSize + root.controlSpacing * 2 + root.rightPadding

    readonly property real metadataMaximumWidth: 300
    readonly property real metadataNaturalWidth: metadataTitle.implicitWidth + (root.trackArtist.length > 0 ? metadataSeparator.implicitWidth + metadataArtist.implicitWidth + metadataRow.spacing * 2 : 0)
    readonly property real metadataPreferredWidth: Math.min(root.metadataMaximumWidth, Math.max(0, root.metadataNaturalWidth))
    readonly property real metadataMinimumWidth: Math.min(root.metadataPreferredWidth, 92)
    readonly property bool metadataCapped: root.metadataNaturalWidth > root.metadataMaximumWidth
    readonly property real metadataSeparatorWidth: root.trackArtist.length > 0 ? metadataSeparator.implicitWidth + metadataRow.spacing * 2 : 0
    readonly property real metadataNaturalTextWidth: metadataTitle.implicitWidth + (root.trackArtist.length > 0 ? metadataArtist.implicitWidth : 0)
    readonly property real metadataAvailableCappedTextWidth: Math.max(0, Math.min(root.metadataMaximumWidth, metadataBox.width) - root.metadataSeparatorWidth)
    readonly property real availableMetadataWidth: Math.max(0, root.width - root.leftPadding - root.rightPadding - root.artworkSize - root.waveWidth - root.playButtonVisualSize - root.controlSpacing * 2 - root.metadataSpacing)

    readonly property real minimumWidthHint: root.compactNaturalWidth + (root.detailed ? root.leftPadding : 0) + (root.detailed && root.metadataMinimumWidth > 0 ? root.metadataSpacing + root.metadataMinimumWidth : 0)
    readonly property real preferredWidthHint: root.compactNaturalWidth + (root.detailed ? root.leftPadding : 0) + (root.detailed && root.metadataPreferredWidth > 0 ? root.metadataSpacing + root.metadataPreferredWidth : 0)
    // scene skeletons currently own height; this protocol hint is informational only
    readonly property real preferredHeightHint: 36
    readonly property bool interactive: true

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    property real contentReveal: 0.0
    property real artworkReveal: 0.0

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

    function syncContentReveal() {
        if (!root.widgetVisible) {
            root.contentReveal = 0.0
            root.artworkReveal = 0.0
            return
        }

        root.contentReveal = 0.0
        contentRevealTimer.restart()
        root.syncArtworkReveal(true)
    }

    function syncArtworkReveal(deferReveal) {
        if (!root.widgetVisible || artworkImage.status !== Image.Ready) {
            root.artworkReveal = 0.0
            return
        }

        if (deferReveal) {
            root.artworkReveal = 0.0
            artworkRevealTimer.restart()
        } else {
            root.artworkReveal = 1.0
        }
    }

    function resetWave() {
        for (let i = 0; i < waveRepeater.count; ++i) {
            const item = waveRepeater.itemAt(i)
            if (item)
                item.level = item.idleLevel
        }
    }

    Behavior on contentReveal {
        NumberAnimation {
            duration: 190
            easing.type: Easing.OutCubic
        }
    }

    Behavior on artworkReveal {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: contentRevealTimer
        interval: 1
        repeat: false
        onTriggered: root.contentReveal = root.widgetVisible ? 1.0 : 0.0
    }

    Timer {
        id: artworkRevealTimer
        interval: 1
        repeat: false
        onTriggered: root.artworkReveal = root.widgetVisible && artworkImage.status === Image.Ready ? 1.0 : 0.0
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
        spacing: root.controlSpacing
        opacity: root.contentReveal
        scale: 0.96 + root.contentReveal * 0.04

        Item {
            visible: root.detailed
            width: Math.max(0, root.leftPadding - contentRow.spacing)
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

                onStatusChanged: root.syncArtworkReveal(status === Image.Ready)
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
                opacity: root.artworkReveal
                scale: 0.94 + root.artworkReveal * 0.06
            }
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
            id: metadataBox

            visible: root.detailed
            width: root.detailed ? Math.min(root.metadataPreferredWidth, root.availableMetadataWidth) : 0
            height: root.height
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Row {
                id: metadataRow

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                spacing: 4

                StyledText {
                    id: metadataTitle

                    anchors.verticalCenter: parent.verticalCenter

                    width: {
                        if (!root.metadataCapped)
                            return implicitWidth

                        if (root.trackArtist.length === 0)
                            return Math.min(implicitWidth, root.metadataAvailableCappedTextWidth)

                        if (root.metadataNaturalTextWidth <= 0)
                            return 0

                        return root.metadataAvailableCappedTextWidth * implicitWidth / root.metadataNaturalTextWidth
                    }
                    text: root.trackTitle
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                    elide: root.metadataCapped ? Text.ElideRight : Text.ElideNone
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
                    width: {
                        if (!visible)
                            return 0

                        if (!root.metadataCapped)
                            return implicitWidth

                        if (root.metadataNaturalTextWidth <= 0)
                            return 0

                        return root.metadataAvailableCappedTextWidth * implicitWidth / root.metadataNaturalTextWidth
                    }
                    text: root.trackArtist
                    font.pixelSize: Theme.fontSizeMedium * 0.85
                    font.weight: Font.Bold
                    font.italic: true
                    color: Theme.surfaceVariantText
                    elide: root.metadataCapped ? Text.ElideRight : Text.ElideNone
                    maximumLineCount: 1
                }
            }
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
            width: Math.max(0, root.rightPadding - contentRow.spacing)
            height: 1
        }
    }

    onWidgetVisibleChanged: root.syncContentReveal()
    onArtworkSourceChanged: {
        root.artworkReveal = 0.0
        if (artworkImage.status === Image.Ready)
            root.syncArtworkReveal(true)
    }
    onPlayingChanged: {
        if (!root.playing)
            root.resetWave()
    }

    Component.onCompleted: root.syncContentReveal()
}
