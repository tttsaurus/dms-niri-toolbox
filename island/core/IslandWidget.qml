import QtQuick

Item {
    id: root

    property var widgetState: ({})

    property bool contentAvailable: true
    readonly property bool widgetStateEnabled: root.widgetState?.enabled !== false
    readonly property bool widgetVisible: root.widgetStateEnabled && root.contentAvailable

    property real minimumWidthHint: 1
    property real preferredWidthHint: root.minimumWidthHint
    property real preferredHeightHint: 36

    signal activated()
    signal statePatchRequested(var patch)
    signal accessRequested(var request)

    function patchState(patch) {
        if (!patch || typeof patch !== "object")
            return

        root.statePatchRequested(Object.assign({}, patch))
    }

    function requestAccess(request) {
        if (!request || typeof request !== "object")
            return

        root.accessRequested(Object.assign({}, request))
    }
}
