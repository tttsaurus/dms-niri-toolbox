import QtQuick

import qs.Common
import qs.Widgets

import "../../core" as Core

Core.IslandWidget {
    id: root

    contentAvailable: true
    minimumWidthHint: 16
    preferredWidthHint: 16
    preferredHeightHint: 36

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint
}
