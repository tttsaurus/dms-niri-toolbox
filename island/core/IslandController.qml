import QtQuick

Item {
    id: root

    visible: false
    width: 0
    height: 0

    readonly property string mode: _mode
    readonly property var currentEvent: _currentEvent

    property string _mode: "compact"
    property var _currentEvent: null

    Timer {
        id: timeoutTimer
        repeat: false
        onTriggered: root.clear()
    }

    function push(event) {
        if (!event)
            return

        // clone the envelope so every push has a fresh object identity and
        // therefore reliably invalidates bindings even for repeated event types
        const next = Object.assign({}, event)
        const presentation = String(next.presentation ?? "peek")

        switch (presentation) {
            case "compact":
            case "peek":
            case "expanded":
                root._mode = presentation
                break
            default:
                console.warn("[IslandController] unknown presentation: ", presentation, "- falling back to peek")
                root._mode = "peek"
                break
        }

        root._currentEvent = next

        timeoutTimer.stop()

        const ttl = Number(next.ttl ?? 0)
        if (Number.isFinite(ttl) && ttl > 0) {
            timeoutTimer.interval = Math.floor(ttl)
            timeoutTimer.start()
        }
    }

    function clear() {
        timeoutTimer.stop()
        root._currentEvent = null
        root._mode = "compact"
    }
}
