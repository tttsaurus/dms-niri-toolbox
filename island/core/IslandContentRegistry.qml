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
            case "musicControlsLauncher":
                return Qt.resolvedUrl("../content/widgets/MusicControlsLauncherWidget.qml")
            case "musicControls":
                return Qt.resolvedUrl("../content/widgets/MusicControlsWidget.qml")
            default:
                return ""
        }
    }

    function peekCompanionFor(widgetId) {
        switch (String(widgetId ?? "")) {
            case "musicTrack":
                return {
                    widgetId: "musicControlsLauncher",
                    side: "right",
                    square: true,
                    activationRequest: {
                        navigation: "push",
                        presentation: "expanded",
                        context: {
                            widgetId: "musicControls",
                            title: "Music",
                            backOnWidgetActivation: true,
                            backWhenWidgetUnavailable: true
                        },
                        notificationPolicy: "keep"
                    }
                }
            default:
                return null
        }
    }
}
