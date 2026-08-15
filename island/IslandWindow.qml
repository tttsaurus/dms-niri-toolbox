import QtQuick
import Quickshell
import Quickshell.Wayland

import "view" as View

PanelWindow {
    id: root

    required property var modelData
    required property var controller
    required property real compactWidth
    required property real compactMaximumWidth

    property var barAnchor: null

    readonly property bool islandExpanded: root.controller.mode === "expanded"
    readonly property real barSpacing: barAnchor?.barSpacing ?? 4
    readonly property real barThickness: barAnchor?.barThickness ?? 36

    readonly property real reservationWidth: island.barReservationWidth

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

    Region {
        id: islandMask
        item: island
    }

    Region {
        id: expandedMask
        item: root.contentItem
    }

    // expanded must receive the full screen so every click outside the island can dismiss it
    mask: root.islandExpanded ? expandedMask : islandMask

    MouseArea {
        id: dismissArea

        anchors.fill: parent
        z: 0

        visible: root.islandExpanded
        enabled: root.islandExpanded

        onClicked: root.controller.clear()
    }

    View.IslandPresenter {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.barSpacing
        z: 1

        controller: root.controller
        compactWidth: root.compactWidth
        compactHeight: root.barThickness
        compactMaximumWidth: Math.max(root.compactWidth, root.compactMaximumWidth)

        maximumWidth: Math.max(root.compactWidth, root.width)
        maximumHeight: Math.max(root.barThickness, root.height - root.barSpacing)
    }
}