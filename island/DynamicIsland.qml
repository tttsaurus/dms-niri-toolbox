import QtQuick

Item {
    id: root

    required property real targetWidth
    required property real targetHeight
    required property string mode

    property alias contentItem: contentLayer

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

    Behavior on animatedRadius {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    width: targetWidth
    height: targetHeight
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutQuart
        }
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
}