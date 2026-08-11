import QtQuick

QtObject {
    function sourceFor(event) {
        if (!event)
            return Qt.resolvedUrl("../content/IdleContent.qml")

        switch (event.type) {
            case "debugPeek":
                return Qt.resolvedUrl("../content/DebugPeekContent.qml")
            case "debugExpanded":
                return Qt.resolvedUrl("../content/DebugExpandedContent.qml")
            default:
                return Qt.resolvedUrl("../content/IdleContent.qml")
        }
    }
}
