import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    property var barAnchor: null

    readonly property real barCenterY: barAnchor && barAnchor.centerY != null ? barAnchor.centerY : 24

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

        y: root.barCenterY - compactHeight / 2
    }
}