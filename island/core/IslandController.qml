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

    function normalizedPresentation(value, fallback) {
        const presentation = String(value ?? fallback ?? "peek")
        switch (presentation) {
            case "compact":
            case "peek":
            case "expanded":
                return presentation
            default:
                console.warn(
                    "[IslandController] unknown presentation: ",
                    presentation,
                    "- falling back to ",
                    fallback ?? "peek"
                )
                return String(fallback ?? "peek")
        }
    }

    function push(event) {
        if (!event)
            return

        const next = Object.assign({}, event)
        const presentation = root.normalizedPresentation(next.presentation, "peek")

        root._currentEvent = next
        root._mode = presentation

        timeoutTimer.stop()
        const ttl = Number(next.ttl ?? 0)
        if (Number.isFinite(ttl) && ttl > 0) {
            timeoutTimer.interval = Math.floor(ttl)
            timeoutTimer.start()
        }
    }

    function requestPresentation(presentation) {
        root._mode = root.normalizedPresentation(presentation, root._mode)
    }

    function clear() {
        timeoutTimer.stop()
        root._currentEvent = null
        root._mode = "compact"
    }
}
