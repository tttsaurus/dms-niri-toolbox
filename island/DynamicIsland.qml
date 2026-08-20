import QtQuick

import qs.Common

Item {
    id: root

    property alias contentItem: contentLayer

    required property real targetWidth
    required property real targetHeight
    required property string mode

    property bool splitEnabled: false
    property real splitPercentage: 0.5

    property var baseColorHint: null
    property var glowColorHint: null
    property var edgeColorHint: null

    // -------------------- Config Reading --------------------

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    readonly property real shapeInset: {
        const value = Number(pluginData.islandGeometryInset ?? 5)
        return Number.isFinite(value) ? Math.floor(value) : 5
    }

    readonly property real targetRadius: root._targetRadius

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
                return clamp(root.islandCompactRadius, 0, Math.min(root.targetWidth, root.targetHeight) / 2)
            case "peek":
                return clamp(root.islandPeekRadius, 0, Math.min(root.targetWidth, root.targetHeight) / 2)
            case "expanded":
                return clamp(root.islandExpandedRadius, 0, Math.min(root.targetWidth, root.targetHeight) / 2)
            default:
                return 18
        }
    }

    // compact mode shader settings
    
    readonly property color baseColorCompact: {
        const value = pluginData.baseColorCompact ?? "#000000"
        if (typeof value !== "string")
            return "#000000"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#000000"
    }

    readonly property color glowColorCompact: {
        const value = pluginData.glowColorCompact ?? "#1b3554"
        if (typeof value !== "string")
            return "#1b3554"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#1b3554"
    }

    readonly property color edgeColorCompact: {
        const value = pluginData.edgeColorCompact ?? "#9fb8db"
        if (typeof value !== "string")
            return "#9fb8db"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#9fb8db"
    }

    readonly property int shadowWidthCompact: {
        const value = Number(pluginData.shadowWidthCompact ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityCompact: {
        const value = Number(pluginData.shadowIntensityCompact ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? value : 0.3));
    }

    readonly property bool interiorGlowCompact: pluginData.interiorGlowCompact ?? true
    readonly property bool innerEdgeHighlightCompact: pluginData.innerEdgeHighlightCompact ?? true
    readonly property bool followDmsColorSettingsCompact: pluginData.followDmsColorSettingsCompact ?? false

    // peek mode shader settings
    
    readonly property color baseColorPeek: {
        const value = pluginData.baseColorPeek ?? "#000000"
        if (typeof value !== "string")
            return "#000000"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#000000"
    }

    readonly property color glowColorPeek: {
        const value = pluginData.glowColorPeek ?? "#1b3554"
        if (typeof value !== "string")
            return "#1b3554"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#1b3554"
    }

    readonly property color edgeColorPeek: {
        const value = pluginData.edgeColorPeek ?? "#9fb8db"
        if (typeof value !== "string")
            return "#9fb8db"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#9fb8db"
    }

    readonly property int shadowWidthPeek: {
        const value = Number(pluginData.shadowWidthPeek ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityPeek: {
        const value = Number(pluginData.shadowIntensityPeek ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? value : 0.3));
    }

    readonly property bool interiorGlowPeek: pluginData.interiorGlowPeek ?? true
    readonly property bool innerEdgeHighlightPeek: pluginData.innerEdgeHighlightPeek ?? true
    readonly property bool followDmsColorSettingsPeek: pluginData.followDmsColorSettingsPeek ?? false

    // expanded mode shader settings
    
    readonly property color baseColorExpanded: {
        const value = pluginData.baseColorExpanded ?? "#000000"
        if (typeof value !== "string")
            return "#000000"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#000000"
    }

    readonly property color glowColorExpanded: {
        const value = pluginData.glowColorExpanded ?? "#1b3554"
        if (typeof value !== "string")
            return "#1b3554"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#1b3554"
    }

    readonly property color edgeColorExpanded: {
        const value = pluginData.edgeColorExpanded ?? "#9fb8db"
        if (typeof value !== "string")
            return "#9fb8db"
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : "#9fb8db"
    }

    readonly property int shadowWidthExpanded: {
        const value = Number(pluginData.shadowWidthExpanded ?? 4)
        return Number.isFinite(value) ? Math.floor(value) : 4
    }

    readonly property real shadowIntensityExpanded: {
        const value = Number(pluginData.shadowIntensityExpanded ?? 0.3)
        return Math.max(0.0, Math.min(0.9, Number.isFinite(value) ? value : 0.3));
    }

    readonly property bool interiorGlowExpanded: pluginData.interiorGlowExpanded ?? true
    readonly property bool innerEdgeHighlightExpanded: pluginData.innerEdgeHighlightExpanded ?? true
    readonly property bool followDmsColorSettingsExpanded: pluginData.followDmsColorSettingsExpanded ?? false

    // switch processed shader settings

    readonly property color _baseColor: {
        switch (root.mode) {
            case "compact":
                return root.baseColorCompact
            case "peek":
                return root.baseColorPeek
            case "expanded":
                return root.baseColorExpanded
            default:
                return "#000000"
        }
    }

    readonly property color _glowColor: {
        switch (root.mode) {
            case "compact":
                return root.glowColorCompact
            case "peek":
                return root.glowColorPeek
            case "expanded":
                return root.glowColorExpanded
            default:
                return "#1b3554"
        }
    }

    readonly property color _edgeColor: {
        switch (root.mode) {
            case "compact":
                return root.edgeColorCompact
            case "peek":
                return root.edgeColorPeek
            case "expanded":
                return root.edgeColorExpanded
            default:
                return "#9fb8db"
        }
    }

    readonly property int _shadowWidth: {
        switch (root.mode) {
            case "compact":
                return root.shadowWidthCompact
            case "peek":
                return root.shadowWidthPeek
            case "expanded":
                return root.shadowWidthExpanded
            default:
                return 4
        }
    }

    readonly property real _shadowIntensity: {
        switch (root.mode) {
            case "compact":
                return root.shadowIntensityCompact
            case "peek":
                return root.shadowIntensityPeek
            case "expanded":
                return root.shadowIntensityExpanded
            default:
                return 0.3
        }
    }

    readonly property bool _interiorGlow: {
        switch (root.mode) {
            case "compact":
                return root.interiorGlowCompact
            case "peek":
                return root.interiorGlowPeek
            case "expanded":
                return root.interiorGlowExpanded
            default:
                return true
        }
    }

    readonly property bool _innerEdgeHighlight: {
        switch (root.mode) {
            case "compact":
                return root.innerEdgeHighlightCompact
            case "peek":
                return root.innerEdgeHighlightPeek
            case "expanded":
                return root.innerEdgeHighlightExpanded
            default:
                return true
        }
    }

    readonly property bool _followDmsColorSettings: {
        switch (root.mode) {
            case "compact":
                return root.followDmsColorSettingsCompact
            case "peek":
                return root.followDmsColorSettingsPeek
            case "expanded":
                return root.followDmsColorSettingsExpanded
            default:
                return false
        }
    }

    readonly property color baseColor: root.baseColorHint ?? root._baseColor
    readonly property color glowColor: root.glowColorHint ?? (
            root._followDmsColorSettings 
                ? Theme.surfaceTint
                : root._glowColor
        )
    readonly property color edgeColor: root.edgeColorHint ?? (
            root._followDmsColorSettings
                ? Theme.outline
                : root._edgeColor
        )
    readonly property int shadowWidth: clamp(root._shadowWidth, 0, root.shapeInset)
    readonly property real shadowIntensity: root._shadowIntensity
    readonly property bool interiorGlow: root._interiorGlow
    readonly property bool innerEdgeHighlight: root._innerEdgeHighlight

    // ------------------------------------------------------------

    property real animatedRadius: root.targetRadius
    Behavior on animatedRadius {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    property color animatedBaseColor: root.baseColor
    Behavior on animatedBaseColor {
        ColorAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    property color animatedGlowColor: root.glowColor
    Behavior on animatedGlowColor {
        ColorAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    property color animatedEdgeColor: root.edgeColor
    Behavior on animatedEdgeColor {
        ColorAnimation {
            duration: 240
            easing.type: Easing.OutQuart
        }
    }

    property real animatedSplit: root.splitEnabled ? 1.0 : 0.0
    Behavior on animatedSplit {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutQuart
        }
    }

    property real animatedSplitPercentage: root.splitPercentage
    Behavior on animatedSplitPercentage {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutQuart
        }
    }

    property real animatedInteriorGlow: root.interiorGlow ? 1.0 : 0.0
    Behavior on animatedInteriorGlow {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuart
        }
    }

    property real animatedInnerEdgeHighlight: root.innerEdgeHighlight ? 1.0 : 0.0
    Behavior on animatedInnerEdgeHighlight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuart
        }
    }

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
        property color baseColor: root.animatedBaseColor
        property color glowColor: root.animatedGlowColor
        property color edgeColor: root.animatedEdgeColor
        property real time: root.shaderTime
        property real edgeStrength: 0.82
        property real flowStrength: 0.92
        property real shapeInset: root.shapeInset
        property real shadowWidth: root.shadowWidth
        property real shadowIntensity: root.shadowIntensity
        property real interiorGlow: root.animatedInteriorGlow
        property real innerEdgeHighlight: root.animatedInnerEdgeHighlight
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

            x: -root.shapeInset
            y: -root.shapeInset
            width: root.width
            height: root.height
        }
    }
}
