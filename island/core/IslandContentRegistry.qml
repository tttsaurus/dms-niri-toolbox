import QtQuick

QtObject {
    id: root

    function sceneSourceFor(mode) {
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

    function notificationSourceFor(notification) {
        switch (String(notification?.type ?? "")) {
            case "javaVersionSwitch":
                return Qt.resolvedUrl("../content/notifications/JavaVersionSwitchNotification.qml")
            default:
                return ""
        }
    }

    function widgetSourceFor(widgetId) {
        switch (String(widgetId ?? "")) {
            case "clock":
                return Qt.resolvedUrl("../content/widgets/ClockWidget.qml")
            case "musicTrack":
                return Qt.resolvedUrl("../content/widgets/MusicTrackWidget.qml")
            default:
                return ""
        }
    }
}