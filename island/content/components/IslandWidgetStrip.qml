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

    signal activated(string widgetId)
    signal statePatchRequested(string widgetId, var patch)
    signal actionRequested(string widgetId, string action, var payload)
    signal accessRequested(var request)

    readonly property real naturalWidth: widgetRow.implicitWidth
    readonly property int count: widgetRepeater.count

    implicitWidth: root.naturalWidth
    implicitHeight: root.hostHeight

    function widgetIdFor(entry) {
        if (entry && typeof entry === "object")
            return String(entry.widgetId ?? entry.id ?? "")
        return String(entry ?? "")
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

                readonly property string widgetId: root.widgetIdFor(modelData)
                readonly property real widgetPresence: widgetHost.visibilityProgress
                readonly property real leadingSpacing: index > 0
                    ? root.spacing * widgetHost.visibilityProgress * root.presenceBefore(index)
                    : 0

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

                    onActivated: root.activated(widgetSlot.widgetId)
                    onStatePatchRequested: patch => root.statePatchRequested(widgetSlot.widgetId, patch)
                    onActionRequested: (action, payload) => root.actionRequested(widgetSlot.widgetId, action, payload)
                    onAccessRequested: request => root.accessRequested(request)
                }
            }
        }
    }
}
