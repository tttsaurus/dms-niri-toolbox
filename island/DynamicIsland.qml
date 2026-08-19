import QtQuick

Item {
    id: root

    required property real targetWidth
    required property real targetHeight
    required property string mode

    property bool splitEnabled: false
    property real splitPercentage: 0.5

    property alias contentItem: contentLayer

    readonly property real shapeInset: 5.0
    readonly property real targetRadius: root._targetRadius
    readonly property int geometryAnimationDuration: 260

    property bool _geometryReady: false
    property real _geometryStartWidth: 0
    property real _geometryStartHeight: 0
    property real _geometryEndWidth: 0
    property real _geometryEndHeight: 0

    readonly property int islandCompactRadius: {
        const value = Number(pluginData.islandCompactRadius ?? 18)
        return Number.isFinite(value) ? Math.floor(value) : 18
    }
    readonly property int islandPeekRadius: {
        const value = Number(pluginData.islandPeekRadius ?? 18)
        return Number.isFinite(value) ? Math.floor(value) : 18
    }
    readonly property int islandExpandedRadius: {
        const value = Number(pluginData.islandExpandedRadius ?? 28)
        return Number.isFinite(value) ? Math.floor(value) : 28
    }

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function scheduleGeometryCommit() {
        if (root._geometryReady)
            geometryCommitTimer.restart()
    }

    function geometryEndpointMatches(widthValue, heightValue) {
        return Math.abs(root._geometryEndWidth - widthValue) < 0.01
            && Math.abs(root._geometryEndHeight - heightValue) < 0.01
    }

    function geometryMatches(widthValue, heightValue) {
        return Math.abs(root.width - widthValue) < 0.01
            && Math.abs(root.height - heightValue) < 0.01
    }

    function applyGeometryProgress(value) {
        const progress = root.clamp(Number(value), 0, 1)
        root.width = root._geometryStartWidth + (root._geometryEndWidth - root._geometryStartWidth) * progress
        root.height = root._geometryStartHeight + (root._geometryEndHeight - root._geometryStartHeight) * progress
    }

    function snapGeometry(widthValue, heightValue) {
        root._geometryStartWidth = widthValue
        root._geometryStartHeight = heightValue
        root._geometryEndWidth = widthValue
        root._geometryEndHeight = heightValue
        geometryClock.progress = 1.0
        root.width = widthValue
        root.height = heightValue
    }

    function finishGeometryCommit() {
        root.applyGeometryProgress(1.0)

        const nextWidth = Number(root.targetWidth)
        const nextHeight = Number(root.targetHeight)
        if (!root.geometryEndpointMatches(nextWidth, nextHeight))
            root.scheduleGeometryCommit()
    }

    function commitGeometry(animated) {
        const nextWidth = Number(root.targetWidth)
        const nextHeight = Number(root.targetHeight)
        if (!Number.isFinite(nextWidth) || nextWidth <= 0 || !Number.isFinite(nextHeight) || nextHeight <= 0) return

        geometryCommitTimer.stop()

        if (geometryAnimation.running && root.geometryEndpointMatches(nextWidth, nextHeight)) return

        const currentWidth = root.width
        const currentHeight = root.height
        geometryAnimation.stop()

        if (!animated || currentWidth <= 0 || currentHeight <= 0) {
            root.snapGeometry(nextWidth, nextHeight)
            return
        }

        if (root.geometryMatches(nextWidth, nextHeight)) {
            root.snapGeometry(nextWidth, nextHeight)
            return
        }

        root._geometryStartWidth = currentWidth
        root._geometryStartHeight = currentHeight
        root._geometryEndWidth = nextWidth
        root._geometryEndHeight = nextHeight
        geometryClock.progress = 0.0
        root.applyGeometryProgress(0.0)
        geometryAnimation.restart()
    }

    readonly property real _targetRadius: {
        switch (root.mode) {
            case "compact":
                return clamp(root.islandCompactRadius, 0, Math.min(targetWidth, targetHeight) / 2)
            case "peek":
                return clamp(root.islandPeekRadius, 0, Math.min(targetWidth, targetHeight) / 2)
            case "expanded":
                return clamp(root.islandExpandedRadius, 0, Math.min(targetWidth, targetHeight) / 2)
            default:
                return 18
        }
    }

    property real animatedRadius: root._targetRadius
    property real animatedSplit: root.splitEnabled ? 1.0 : 0.0
    property real animatedSplitPercentage: root.splitPercentage

    Behavior on animatedRadius {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    Behavior on animatedSplit {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutQuart
        }
    }

    Behavior on animatedSplitPercentage {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutQuart
        }
    }

    property bool islandInteriorGlow: true
    property real animatedIslandInteriorGlow: root.islandInteriorGlow ? 1.0 : 0.0
    Behavior on animatedIslandInteriorGlow {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuart
        }
    }

    property bool islandInnerEdgeHighlight: true
    property real animatedIslandInnerEdgeHighlight: root.islandInnerEdgeHighlight ? 1.0 : 0.0
    Behavior on animatedIslandInnerEdgeHighlight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuart
        }
    }

    property color islandBaseColor: "#000000"
    property color islandGlowColor: "#1b3554"
    property color islandEdgeColor: "#9fb8db"

    property real shaderTime: 0
    NumberAnimation {
        target: root
        property: "shaderTime"
        from: 0
        to: Math.PI * 2
        duration: 9000
        loops: Animation.Infinite
        running: root.visible
    }

    width: 0
    height: 0
    clip: true

    onTargetWidthChanged: root.scheduleGeometryCommit()
    onTargetHeightChanged: root.scheduleGeometryCommit()

    Timer {
        id: geometryCommitTimer

        interval: 0
        repeat: false
        onTriggered: root.commitGeometry(true)
    }

    QtObject {
        id: geometryClock

        property real progress: 1.0
        onProgressChanged: root.applyGeometryProgress(progress)
    }

    NumberAnimation {
        id: geometryAnimation

        target: geometryClock
        property: "progress"
        from: 0.0
        to: 1.0
        duration: root.geometryAnimationDuration
        easing.type: Easing.OutQuart
        onFinished: root.finishGeometryCommit()
    }

    // keep a visible fallback until the local .qsb has been baked,
    // and also if the scene graph backend rejects the ShaderEffect for any reason
    Rectangle {
        anchors.fill: parent
        visible: shaderEffect.status !== ShaderEffect.Compiled
        color: "black"
        radius: root.animatedRadius
    }

    ShaderEffect {
        id: shaderEffect
        anchors.fill: parent

        property vector2d sizeDip: Qt.vector2d(
            Math.max(width, 1),
            Math.max(height, 1)
        )

        property real radiusDip: root.animatedRadius
        property color baseColor: root.islandBaseColor
        property color glowColor: root.islandGlowColor
        property color edgeColor: root.islandEdgeColor
        property real time: root.shaderTime
        property real edgeStrength: 0.82
        property real flowStrength: 0.92
        property real shapeInset: root.shapeInset
        property real shadowWidth: 4.0
        property real shadowIntensity: 0.3
        property real interiorGlow: root.animatedIslandInteriorGlow
        property real innerEdgeHighlight: root.animatedIslandInnerEdgeHighlight
        property real enableSplit: root.animatedSplit
        property real splitPercentage: root.clamp(root.animatedSplitPercentage, 0.01, 0.99)

        fragmentShader: Qt.resolvedUrl("shaders/dynamic_island.frag.qsb")

        onStatusChanged: {
            if (status === ShaderEffect.Error)
                console.warn("[DynamicIsland] shader error: ", log)
        }
    }

    Item {
        id: contentLayer
        anchors.fill: parent
    }

    Component.onCompleted: {
        root._geometryReady = true
        root.commitGeometry(false)
    }
}
