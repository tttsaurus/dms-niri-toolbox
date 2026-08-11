import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    property var barAnchor: null

    required property real compactWidth

    readonly property real barCenterY: barAnchor && barAnchor.centerY != null ? barAnchor.centerY : 24
    readonly property real barThickness: barAnchor && barAnchor.barThickness != null ? barAnchor.barThickness : 36

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
        
        y: root.barCenterY - compactHeight / 2
    }
}