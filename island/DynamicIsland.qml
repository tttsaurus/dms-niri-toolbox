import QtQuick

Item {
    id: root

    required property real targetWidth
    required property real targetHeight
    required property string mode

    property alias contentItem: contentLayer

    readonly property real targetRadius: {
        switch (root.mode) {
            case "compact":
                return 18

            case "peek":
                return 18

            case "expanded":
                return 28

            default:
                return 18
        }
    }

    property real animatedRadius: root.targetRadius

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

        visible: squircleEffect.status !== ShaderEffect.Compiled

        color: "black"
        radius: root.animatedRadius
    }

    ShaderEffect {
        id: squircleEffect

        anchors.fill: parent

        property vector2d sizePx: Qt.vector2d(
            Math.max(width, 1),
            Math.max(height, 1)
        )

        property real radiusPx: root.animatedRadius

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