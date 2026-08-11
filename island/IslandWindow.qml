import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

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

    property var barGeometry: null

    readonly property real barCenterY:
        barGeometry
            ? barGeometry.centerY
            : 24

    DynamicIsland {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        y: window.barCenterY - height / 2
    }
}
