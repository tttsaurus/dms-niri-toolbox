import QtQuick

QtObject {
    id: root

    function sceneSourceFor(presentation) {
        switch (String(presentation)) {
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

    function widgetDefinitionFor(widgetId) {
        switch (String(widgetId ?? "")) {
            case "clock":
                return {
                    widgetId: "clock",
                    source: Qt.resolvedUrl("../content/widgets/ClockWidget.qml"),
                    activations: ({}),
                    presentations: ({}),
                    companions: ({})
                }
            case "musicTrack":
                return {
                    widgetId: "musicTrack",
                    source: Qt.resolvedUrl("../content/widgets/MusicTrackWidget.qml"),
                    activations: {
                        compact: {
                            navigation: "push",
                            widgetId: "musicTrack",
                            presentation: "peek"
                        },
                        peek: {
                            navigation: "back"
                        }
                    },
                    presentations: {
                        compact: {
                            viewOptions: {
                                showMetadata: false
                            }
                        },
                        peek: {
                            viewOptions: {
                                showMetadata: true,
                                metadataWidthLimit: 300
                            }
                        },
                        expanded: {
                            viewOptions: {
                                showMetadata: true
                            }
                        }
                    },
                    companions: {
                        peek: {
                            widgetId: "musicControlsLauncher",
                            side: "right",
                            square: true
                        }
                    }
                }
            case "musicControlsLauncher":
                return {
                    widgetId: "musicControlsLauncher",
                    source: Qt.resolvedUrl("../content/widgets/MusicControlsLauncherWidget.qml"),
                    activations: {
                        peek: {
                            navigation: "push",
                            widgetId: "musicControls",
                            presentation: "expanded"
                        }
                    },
                    presentations: ({}),
                    companions: ({})
                }
            case "musicControls":
                return {
                    widgetId: "musicControls",
                    source: Qt.resolvedUrl("../content/widgets/MusicControlsWidget.qml"),
                    activations: {
                        expanded: {
                            navigation: "back"
                        }
                    },
                    presentations: {
                        expanded: {
                            title: "Music",
                            backWhenUnavailable: true
                        }
                    },
                    companions: ({})
                }
            default:
                return null
        }
    }

    function widgetSourceFor(widgetId) {
        const definition = root.widgetDefinitionFor(widgetId)
        return definition ? definition.source : ""
    }

    function isWidgetRegistered(widgetId) {
        return String(root.widgetSourceFor(widgetId)).length > 0
    }

    function copiedRequest(request) {
        if (!request)
            return null

        const copy = Object.assign({}, request)
        if (request.context)
            copy.context = Object.assign({}, request.context)
        return copy
    }

    function activationRequestFor(widgetId, presentation) {
        const definition = root.widgetDefinitionFor(widgetId)
        if (!definition || !definition.activations)
            return null

        return root.copiedRequest(definition.activations[String(presentation ?? "")])
    }

    function presentationSpecFor(widgetId, presentation) {
        const definition = root.widgetDefinitionFor(widgetId)
        if (!definition || !definition.presentations)
            return ({})

        return Object.assign({}, definition.presentations[String(presentation ?? "")] ?? ({}))
    }

    function viewOptionsFor(widgetId, presentation) {
        const options = root.presentationSpecFor(widgetId, presentation).viewOptions
        return options && typeof options === "object" ? Object.assign({}, options) : ({})
    }

    function companionFor(widgetId, presentation) {
        const definition = root.widgetDefinitionFor(widgetId)
        if (!definition || !definition.companions)
            return null

        const companion = definition.companions[String(presentation ?? "")]
        return companion ? Object.assign({}, companion) : null
    }
}
