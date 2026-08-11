import QtQuick

import qs.Common

Item {
    id: root

    required property var toolboxRoot

    property int reservedWidth: 168

    readonly property string centeringMode: SettingsData.centeringMode

    function mappedCenterWidgets() {
        const configured = toolboxRoot.barConfig?.centerWidgets || []

        return configured.map(
            (widget, index) => {
                if (typeof widget === "string") {
                    return {
                        widgetId: widget,
                        id: widget + "_" + index,
                        enabled: true
                    }
                }

                const object = Object.assign({}, widget)

                object.widgetId = widget.id || widget.widgetId
                object.id = (widget.id || widget.widgetId) + "_" + index
                object.enabled = widget.enabled !== false

                return object
            }
        )
    }

    function makeSpacer(id, size, enabled) {
        return {
            widgetId: "spacer",
            id: id,
            enabled: enabled,
            size: size
        }
    }

    function applyIndexReservation(widgets) {
        const count = widgets.length

        const middle = Math.floor(count / 2)

        /*
        * A B C D
        *     ↓
        * A B [ spacer ] C D
        *
        * Final count is odd, spacer becomes the exact
        * center widget in DMS index mode.
        */
        if (count % 2 === 0) {
            widgets.splice(
                middle,
                0,
                makeSpacer(
                    "__toolbox_island_reservation",
                    root.reservedWidth,
                    true
                )
            )

            return widgets
        }

        /*
        * A B C
        *
        * We need an even configured count with the two
        * half-spacers as the exact middle pair:
        *
        * X A [left][right] B C
        *
        * X is disabled and only fixes model parity.
        */
        const halfWidth = root.reservedWidth / 2

        widgets.unshift(
            makeSpacer(
                "__toolbox_island_parity_sentinel",
                1,
                false
            )
        )

        widgets.splice(
            middle + 1,
            0,

            makeSpacer(
                "__toolbox_island_reservation_left",
                halfWidth,
                true
            ),

            makeSpacer(
                "__toolbox_island_reservation_right",
                halfWidth,
                true
            )
        )

        return widgets
    }

    function applyGeometricReservation(widgets) {
        widgets.splice(
            Math.floor(
                widgets.length / 2
            ),
            0,

            makeSpacer(
                "__toolbox_island_reservation",
                root.reservedWidth,
                true
            )
        )

        return widgets
    }

    function projectedWidgets() {
        const widgets = mappedCenterWidgets()

        if (!toolboxRoot.dynamicIslandEnabled)
            return widgets

        switch (root.centeringMode) {
            case "index":
                return applyIndexReservation(widgets)

            case "geometric":
                return applyGeometricReservation(widgets)

            default:
                return widgets
        }
    }

    Binding {
        target: root.toolboxRoot.blurBarWindow ? root.toolboxRoot.blurBarWindow.centerWidgetsModel : null

        property: "values"

        when: root.toolboxRoot.blurBarWindow !== null

        value: root.projectedWidgets()
    }
}