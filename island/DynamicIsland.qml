import QtQuick

Item {
    id: root

    property alias contentItem: contentLayer

    required property real targetWidth
    required property real targetHeight
    required property string mode

    property bool splitEnabled: false
    property real splitPercentage: 0.5

    readonly property real shapeInset: {
        const value = Number(pluginData.islandGeometryInset ?? 5)
        return Number.isFinite(value) ? Math.floor(value) : 5
    }
    readonly property real targetRadius: root._targetRadius

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

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

    AnimatedGeometry {
        target: root
        targetWidth: root.targetWidth
        targetHeight: root.targetHeight

        duration: 260
        easingType: Easing.OutQuart
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
        id: contentClip

        anchors.fill: parent
        anchors.margins: root.shapeInset
        clip: true

        Item {
            id: contentLayer

            anchors.fill: parent
        }
    }
}
