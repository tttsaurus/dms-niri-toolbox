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
            case "test1":
                return {
                    source: Qt.resolvedUrl("../content/widgets/Test1Widget.qml"),
                    activations: {
                        compact: {
                            navigation: "push",
                            widgetId: "test2",
                            presentation: "peek"
                        }
                    }
                }
            case "test2":
                return {
                    source: Qt.resolvedUrl("../content/widgets/Test2Widget.qml"),
                    activations: {
                        peek: {
                            navigation: "back"
                        }
                    },
                    companions: {
                        peek: {
                            widgetId: "test3Launcher",
                            side: "right",
                            square: true
                        }
                    }
                }
            case "test3":
                return {
                    source: Qt.resolvedUrl("../content/widgets/Test3Widget.qml"),
                    activations: {
                        peek: {
                            navigation: "back"
                        }
                    }
                }
            case "test3Launcher":
                return {
                    source: Qt.resolvedUrl("../content/widgets/Test3LauncherWidget.qml"),
                    activations: {
                        peek: {
                            navigation: "push",
                            widgetId: "test3",
                            presentation: "peek"
                        }
                    }
                }
            case "spacer":
                return {
                    source: Qt.resolvedUrl("../content/widgets/SpacerWidget.qml")
                }
            case "clock":
                return {
                    source: Qt.resolvedUrl("../content/widgets/ClockWidget.qml")
                }
            case "musicTrack":
                return {
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
                    source: Qt.resolvedUrl("../content/widgets/MusicControlsLauncherWidget.qml"),
                    activations: {
                        peek: {
                            navigation: "push",
                            widgetId: "musicControls",
                            presentation: "expanded"
                        }
                    }
                }
            case "musicControls":
                return {
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
                    }
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
