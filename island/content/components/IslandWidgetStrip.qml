import QtQuick

Item {
    id: root

    required property var registry

    property var widgets: []
    property var widgetStates: ({})
    property string presentation: "compact"
    property real spacing: 6
    property real hostInset: 0
    property real hostHeight: root.height
    property bool animateVisibility: true

    readonly property var baseColorHint: root.firstColorHint("baseColorHint")
    readonly property var glowColorHint: root.firstColorHint("glowColorHint")
    readonly property var edgeColorHint: root.firstColorHint("edgeColorHint")

    signal statePatchRequested(string widgetId, var patch)
    signal accessRequested(var request)

    readonly property real naturalWidth: widgetRow.implicitWidth

    implicitWidth: root.naturalWidth
    implicitHeight: root.hostHeight

    function firstColorHint(propertyName) {
        for (let i = 0; i < widgetRepeater.count; ++i) {
            const slot = widgetRepeater.itemAt(i)
            if (!slot || !slot.colorHintActive)
                continue

            const value = slot[propertyName]
            if (value !== null && typeof value !== "undefined")
                return value
        }

        return null
    }

    function widgetStateFor(widgetId) {
        const id = String(widgetId ?? "")
        return id.length > 0 && root.widgetStates ? (root.widgetStates[id] ?? ({})) : ({})
    }

    function presenceBefore(index) {
        let presence = 0.0
        for (let i = 0; i < index; ++i) {
            const slot = widgetRepeater.itemAt(i)
            if (slot)
                presence = Math.max(presence, Number(slot.widgetPresence) || 0)
        }
        return presence
    }

    Row {
        id: widgetRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            id: widgetRepeater

            model: root.widgets ?? []

            delegate: Item {
                id: widgetSlot

                readonly property string widgetId: String(modelData ?? "")
                readonly property real widgetPresence: widgetHost.visibilityProgress
                readonly property real leadingSpacing: index > 0
                    ? root.spacing * widgetHost.visibilityProgress * root.presenceBefore(index)
                    : 0

                readonly property bool colorHintActive: widgetHost.widgetVisible || widgetHost.visibilityProgress > 0.001

                readonly property var baseColorHint: widgetHost.baseColorHint
                readonly property var glowColorHint: widgetHost.glowColorHint
                readonly property var edgeColorHint: widgetHost.edgeColorHint

                width: widgetSlot.leadingSpacing + widgetHost.layoutWidth
                height: root.height
                clip: true

                IslandWidgetHost {
                    id: widgetHost

                    x: widgetSlot.leadingSpacing
                    width: preferredWidthHint
                    height: widgetSlot.height

                    registry: root.registry
                    widgetId: widgetSlot.widgetId
                    presentation: root.presentation
                    widgetState: root.widgetStateFor(widgetSlot.widgetId)
                    hostInset: root.hostInset
                    hostHeight: root.hostHeight
                    animateVisibility: root.animateVisibility

                    onStatePatchRequested: function(patch) {
                        root.statePatchRequested(widgetSlot.widgetId, patch)
                    }

                    onAccessRequested: function(request) {
                        root.accessRequested(Object.assign({}, request))
                    }
                }
            }
        }
    }
}
