import QtQuick

Item {
    id: root

    required property Item target
    required property real targetWidth
    required property real targetHeight

    property int duration: 260
    property int easingType: Easing.OutQuart

    property bool _ready: false
    property real _startWidth: 0
    property real _startHeight: 0
    property real _endWidth: 0
    property real _endHeight: 0

    width: 0
    height: 0

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function scheduleCommit() {
        if (root._ready)
            commitTimer.restart()
    }

    function endpointMatches(widthValue, heightValue) {
        return Math.abs(root._endWidth - widthValue) < 0.01 && Math.abs(root._endHeight - heightValue) < 0.01
    }

    function geometryMatches(widthValue, heightValue) {
        return Math.abs(root.target.width - widthValue) < 0.01 && Math.abs(root.target.height - heightValue) < 0.01
    }

    function applyProgress(value) {
        const progress = root.clamp(Number(value), 0, 1)

        root.target.width = root._startWidth + (root._endWidth - root._startWidth) * progress
        root.target.height = root._startHeight + (root._endHeight - root._startHeight) * progress
    }

    function snap(widthValue, heightValue) {
        root._startWidth = widthValue
        root._startHeight = heightValue
        root._endWidth = widthValue
        root._endHeight = heightValue

        animationClock.progress = 1.0

        root.target.width = widthValue
        root.target.height = heightValue
    }

    function finishCommit() {
        root.applyProgress(1.0)

        const nextWidth = Number(root.targetWidth)
        const nextHeight = Number(root.targetHeight)

        if (!root.endpointMatches(nextWidth, nextHeight))
            root.scheduleCommit()
    }

    function commit(animated) {
        const nextWidth = Number(root.targetWidth)
        const nextHeight = Number(root.targetHeight)

        if (!Number.isFinite(nextWidth)
                || nextWidth <= 0
                || !Number.isFinite(nextHeight)
                || nextHeight <= 0) return

        commitTimer.stop()

        if (geometryAnimation.running && root.endpointMatches(nextWidth, nextHeight))
            return

        const currentWidth = root.target.width
        const currentHeight = root.target.height

        geometryAnimation.stop()

        if (!animated || currentWidth <= 0 || currentHeight <= 0) {
            root.snap(nextWidth, nextHeight)
            return
        }

        if (root.geometryMatches(nextWidth, nextHeight)) {
            root.snap(nextWidth, nextHeight)
            return
        }

        root._startWidth = currentWidth
        root._startHeight = currentHeight
        root._endWidth = nextWidth
        root._endHeight = nextHeight

        animationClock.progress = 0.0
        root.applyProgress(0.0)

        geometryAnimation.restart()
    }

    onTargetWidthChanged: root.scheduleCommit()
    onTargetHeightChanged: root.scheduleCommit()

    Timer {
        id: commitTimer

        interval: 0
        repeat: false

        onTriggered: root.commit(true)
    }

    QtObject {
        id: animationClock

        property real progress: 1.0

        onProgressChanged: root.applyProgress(progress)
    }

    NumberAnimation {
        id: geometryAnimation

        target: animationClock
        property: "progress"

        from: 0.0
        to: 1.0

        duration: root.duration
        easing.type: root.easingType

        onFinished: root.finishCommit()
    }

    Component.onCompleted: {
        root._ready = true
        root.commit(false)
    }
}
