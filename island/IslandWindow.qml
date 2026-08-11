import QtQuick
import Quickshell
import Quickshell.Wayland

import "view" as View

PanelWindow {
    id: root

    required property var modelData
    required property var controller
    required property real compactWidth

    property var barAnchor: null

    readonly property real barSpacing: barAnchor?.barSpacing ?? 4
    readonly property real barThickness: barAnchor?.barThickness ?? 36

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    // keep the layer-shell surface stable. only the inner island changes size
    implicitHeight: root.screen?.height ?? 720

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dms:plugins:toolbox-island"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: island
    }

    View.IslandPresenter {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.barSpacing

        controller: root.controller
        compactWidth: root.compactWidth
        compactHeight: root.barThickness

        maximumWidth: Math.max(root.compactWidth, root.width)
        maximumHeight: Math.max(root.barThickness, root.height - root.barSpacing)
    }
}
