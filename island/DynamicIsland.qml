import QtQuick

Item {
    id: root

    required property real targetWidth
    required property real targetHeight

    property alias contentItem: contentLayer

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
        radius: Math.min(width, height) * 0.35
    }

    ShaderEffect {
        id: squircleEffect

        anchors.fill: parent

        property vector2d sizePx: Qt.vector2d(
            Math.max(width, 1),
            Math.max(height, 1)
        )

        fragmentShader: Qt.resolvedUrl("shaders/island_squircle.frag.qsb")

        onStatusChanged: {
            if (status === ShaderEffect.Error)
                console.warn("[DynamicIsland] squircle shader error: ", log)
        }
    }

    Item {
        id: contentLayer
        anchors.fill: parent
    }
}
