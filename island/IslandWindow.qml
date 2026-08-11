import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
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

    implicitHeight: 460

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dms:plugins:toolbox-island"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: island
    }

    DynamicIsland {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter

        compactWidth: root.compactWidth
        compactHeight: root.barThickness

        y: root.barSpacing
    }
}