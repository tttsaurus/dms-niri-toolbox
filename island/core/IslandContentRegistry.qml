import QtQuick

QtObject {
    id: root

    function sceneSourceFor(mode, event) {
        const type = String(event?.type ?? "")

        if (mode === "peek" && type === "debugPeek")
            return Qt.resolvedUrl("../content/DebugPeekContent.qml")
        if (mode === "expanded" && type === "debugExpanded")
            return Qt.resolvedUrl("../content/DebugExpandedContent.qml")

        switch (String(mode)) {
            case "compact":
                return Qt.resolvedUrl("../content/IdleContent.qml")
            case "peek":
                return Qt.resolvedUrl("../content/PeekContent.qml")
            case "expanded":
                return Qt.resolvedUrl("../content/ExpandedContent.qml")
            default:
                return Qt.resolvedUrl("../content/IdleContent.qml")
        }
    }

    function notificationSourceFor(event) {
        const type = String(event?.type ?? "")
        switch (type) {
            case "javaVersionSwitch":
                return Qt.resolvedUrl("../content/notifications/JavaVersionSwitchNotification.qml")
            default:
                return ""
        }
    }
}
