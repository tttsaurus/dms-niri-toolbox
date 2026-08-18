import QtQuick

import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets

import "../components"

Item {
    id: root

    property var toolboxRoot: null

    property var javaOptions: []
    property var javaPathByLabel: ({})

    property string selectedJavaPath: ""

    property string statusText: "Scan for installed JDKs to begin."
    property bool statusError: false

    readonly property bool busy: 
        scanProcess.running || 
        switchProcess.running || 
        checkProcess.running ||
        debugProcess.running

    function scriptPath(name) {
        // Qt.resolvedUrl() returns file:///...
        let url = Qt.resolvedUrl("../scripts/" + name).toString();

        if (url.indexOf("file://") === 0)
            url = url.substring(7);

        return decodeURIComponent(url);
    }

    function setResult(text, error) {
        statusText = text.trim();
        statusError = error;
    }

    function publishIslandEvent(event) {
        const toolbox = root.toolboxRoot
        if (!toolbox || !toolbox.dynamicIslandEnabled || !toolbox.pluginService || !toolbox.pluginId)
            return

        toolbox.pluginService.setGlobalVar(toolbox.pluginId, "islandEvent",
            {
                token: "java-switch-" + Date.now() + "-" + Math.random(),
                event: event
            }
        )
    }

    function parseJavaMajorVersion(text) {
        const input = String(text ?? "");

        const versionMatch = input.match(/\bversion\s+"([^"]+)"/i);
        if (!versionMatch)
            return -1;

        const numberMatch = versionMatch[1].match(/^(\d+)(?:\.(\d+))?/);
        if (!numberMatch)
            return -1;

        const first = parseInt(numberMatch[1], 10);

        if (first === 1 && numberMatch[2] !== undefined)
            return parseInt(numberMatch[2], 10);

        return first;
    }

    function parseJavaInstallations(output) {
        let options = [];
        let pathMap = {};

        const text = output.trim();

        if (text.length === 0) {
            javaOptions = [];
            javaPathByLabel = ({});
            selectedJavaPath = "";

            javaDropdown.currentValue = "";

            setResult("No JDK installations found.", true);
            return;
        }

        const lines = text.split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            const separator = line.indexOf("\t");

            if (separator <= 0)
                continue;

            let label = line.substring(0, separator);
            const path = line.substring(separator + 1);

            if (path.length === 0)
                continue;

            if (pathMap[label] !== undefined)
                label += " [" + path + "]";

            options.push(label);
            pathMap[label] = path;
        }

        javaOptions = options;
        javaPathByLabel = pathMap;

        if (options.length > 0) {
            javaDropdown.currentValue = options[0];
            selectedJavaPath = pathMap[options[0]];

            setResult("Found " + options.length + " JDK installation" + (options.length === 1 ? "." : "s."), false);
        } else {
            javaDropdown.currentValue = "";
            selectedJavaPath = "";

            setResult("No valid JDK installations found.", true);
        }
    }

    Process {
        id: scanProcess

        stdout: StdioCollector {
            id: scanStdout
        }

        stderr: StdioCollector {
            id: scanStderr
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const error = scanStderr.text.trim();

                root.setResult(error.length > 0 ? error : "Failed to scan Java installations.", true);
                return;
            }

            root.parseJavaInstallations(scanStdout.text);
        }
    }

    Process {
        id: switchProcess

        stdout: StdioCollector {
            id: switchStdout
        }

        stderr: StdioCollector {
            id: switchStderr
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const error = switchStderr.text.trim();

                root.setResult(error.length > 0 ? error : "Failed to switch Java.", true);
                return;
            }

            root.setResult(switchStdout.text, false);
            root.publishIslandEvent({
                request: "notification",
                type: "javaVersionSwitch",
                ttl: 3200,
                payload: {
                    label: parseJavaMajorVersion(javaDropdown.currentValue)
                }
            });
        }
    }

    Process {
        id: checkProcess

        stdout: StdioCollector {
            id: checkStdout
        }

        stderr: StdioCollector {
            id: checkStderr
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const error = checkStderr.text.trim();

                root.setResult(error.length > 0 ? error : "Failed to check Java.", true);
                return;
            }

            root.setResult(checkStdout.text, false);
        }
    }

    Process {
        id: debugProcess

        stdout: StdioCollector {
            id: debugStdout
        }

        stderr: StdioCollector {
            id: debugStderr
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const error = debugStderr.text.trim();

                root.setResult(error.length > 0 ? error : "Failed to collect Java debug information.", true);
                return;
            }

            root.setResult(debugStdout.text, false);
        }
    }

    Column {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: Theme.spacingM

        StyledText {
            text: "Java Switch"

            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width

            text: "Switch the active Java development environment."

            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText

            wrapMode: Text.WordWrap
        }
    }

    ScrollableColumn {
        id: settingsColumn

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom

            topMargin: Theme.spacingL
        }

        spacing: Theme.spacingM

        // -------------------- Java selection --------------------
        
        StyledRect {
            width: parent.width
            height: javaControlGroup.implicitHeight + Theme.spacingL * 2

            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: javaControlGroup

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    margins: Theme.spacingL
                }

                spacing: Theme.spacingM

                StyledText {
                    width: parent.width

                    text: "Installed JDKs"

                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium

                    color: Theme.surfaceText
                }

                StyledText {
                    width: parent.width

                    text: "Scan common installation directories and select the JDK to use."

                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText

                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width

                    spacing: Theme.spacingM

                    DankDropdown {
                        id: javaDropdown

                        width: Math.max(120, parent.width - scanButton.width - parent.spacing)

                        options: root.javaOptions

                        currentValue: ""
                        emptyText: "No JDK selected"

                        enableFuzzySearch: root.javaOptions.length > 8

                        enabled: !root.busy && root.javaOptions.length > 0

                        onValueChanged: value => {
                            root.selectedJavaPath = root.javaPathByLabel[value] || "";
                        }
                    }

                    DankButton {
                        id: scanButton

                        text: scanProcess.running ? "Scanning..." : "Scan"

                        iconName: "refresh"

                        enabled: !root.busy

                        onClicked: {
                            root.statusError = false;
                            root.statusText = "Scanning for installed JDKs...";

                            scanProcess.exec(["bash", root.scriptPath("scan_java.sh")]);
                        }
                    }
                }

                StyledText {
                    width: parent.width

                    visible: root.selectedJavaPath.length > 0

                    text: root.selectedJavaPath

                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.monoFontFamily

                    color: Theme.surfaceVariantText

                    wrapMode: Text.WrapAnywhere
                }

                DankButton {
                    width: parent.width

                    text: switchProcess.running ? "Switching..." : "Switch Java"

                    iconName: "sync_alt"

                    enabled: !root.busy && root.selectedJavaPath.length > 0

                    onClicked: {
                        root.statusError = false;
                        root.statusText = "Switching Java environment...";

                        switchProcess.exec(["bash", root.scriptPath("switch_java.sh"), root.selectedJavaPath]);
                    }
                }
            }
        }

        // -------------------- Current Java --------------------
        
        StyledRect {
            width: parent.width
            height: currentJavaGroup.implicitHeight + Theme.spacingL * 2

            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: currentJavaGroup

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    margins: Theme.spacingL
                }

                spacing: Theme.spacingM

                StyledText {
                    width: parent.width

                    text: "Current Java"

                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium

                    color: Theme.surfaceText
                }

                StyledText {
                    width: parent.width

                    text: "Check the Java environment currently configured by Toolbox."

                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText

                    wrapMode: Text.WordWrap
                }

                DankButton {
                    width: parent.width

                    text: checkProcess.running ? "Checking..." : "Verify Selected Java Version"

                    iconName: "terminal"

                    enabled: !root.busy

                    onClicked: {
                        root.statusError = false;
                        root.statusText = "Checking Java environment...";

                        checkProcess.exec(["bash", root.scriptPath("check_java.sh")]);
                    }
                }
            }
        }

        // -------------------- Debug Java --------------------

        StyledRect {
            width: parent.width
            height: debugGroup.implicitHeight + Theme.spacingL * 2

            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: debugGroup

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    margins: Theme.spacingL
                }

                spacing: Theme.spacingM

                StyledText {
                    width: parent.width

                    text: "Debug"

                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    width: parent.width

                    text: "Inspect Java-related shell configuration, Toolbox state files, and the current environment."

                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText

                    wrapMode: Text.WordWrap
                }

                DankButton {
                    width: parent.width

                    text: debugProcess.running ? "Collecting..." : "Collect Debug Information"

                    iconName: "bug_report"

                    enabled: !root.busy

                    onClicked: {
                        root.statusError = false
                        root.statusText = "Collecting Java debug information..."

                        debugProcess.exec(["bash", root.scriptPath("debug_java.sh")])
                    }
                }
            }
        }

        // -------------------- Output --------------------
        
        StyledRect {
            width: parent.width
            height: resultGroup.implicitHeight + Theme.spacingL * 2

            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: resultGroup

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    margins: Theme.spacingL
                }

                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    StyledText {
                        width: parent.width - copyButton.width - parent.spacing

                        text: "Result"

                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DankButton {
                        id: copyButton

                        text: "Copy"
                        iconName: "content_copy"

                        enabled: root.statusText.length > 0

                        onClicked: {
                            Quickshell.clipboardText = root.statusText
                        }
                    }
                }

                StyledText {
                    width: parent.width

                    text: root.statusText

                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.monoFontFamily

                    color: root.statusError ? Theme.error : Theme.surfaceVariantText

                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }
}