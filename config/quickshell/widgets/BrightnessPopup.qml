import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// ═════════════════════════════════════════════════════════════════════
//   Brightness popup horizontal — déclenché par le bouton BRT Waybar
//   - Positionné sous le curseur au moment du clic
//   - Scroll / clic / drag
//   - Contrôle du backlight via brightnessctl
// ═════════════════════════════════════════════════════════════════════

ShellRoot {
    id: root

    readonly property int segments: 30
    readonly property int popupWidth: 300
    readonly property int popupHeight: 72
    readonly property int topOffset: 36
    readonly property int hideDelay: 2600

    readonly property int segFilledW: 3
    readonly property int segFilledH: 14
    readonly property int segEmptyW:  4
    readonly property int segEmptyH:  4
    readonly property int segActiveW: 5
    readonly property int segActiveH: 22

    readonly property color colFilled: "#d6b35f"
    readonly property color colEmpty:  "#c8b89a"
    readonly property color colBg:     "#0f0d0a"

    property bool popupOpen: false
    property bool userInteracting: false
    property real brightness: 0.5
    property int localCursorX: 0
    property int lastToggle: 0
    property int lastVolumeToggle: 0
    property string activeMonitor: ""

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function toggleFromCursor() {
        if (popupOpen) {
            popupOpen = false
            return
        }
        cursorProc.running = true
    }

    function openAtCursor(monitorName, x) {
        activeMonitor = monitorName
        localCursorX = x
        popupOpen = true
        getBrightnessProc.running = true
        hideTimer.restart()
    }

    function setBrightness(v) {
        v = clamp(v, 0.01, 1)
        brightness = v
        var pct = Math.max(1, Math.round(v * 100))
        setBrightnessProc.command = ["brightnessctl", "set", pct + "%"]
        setBrightnessProc.running = true
    }

    Process {
        id: toggleWatcher
        command: ["sh","-c","wc -l < /tmp/qs-brightness-popup 2>/dev/null || echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt(this.text.trim()) || 0
                if (n !== root.lastToggle) {
                    root.lastToggle = n
                    root.toggleFromCursor()
                }
            }
        }
    }

    Process {
        id: volumeWatcher
        command: ["sh","-c","wc -l < /tmp/qs-volume-popup 2>/dev/null || echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt(this.text.trim()) || 0
                if (n !== root.lastVolumeToggle) {
                    root.lastVolumeToggle = n
                    root.popupOpen = false
                }
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!toggleWatcher.running) toggleWatcher.running = true
            if (!volumeWatcher.running) volumeWatcher.running = true
        }
    }

    Process {
        id: cursorProc
        command: ["sh","-c","hyprctl cursorpos -j | python3 -c \"\nimport sys,json,subprocess\npos=json.load(sys.stdin)\nmons=json.loads(subprocess.check_output(['hyprctl','monitors','-j']))\nfor m in mons:\n    x,y=m['x'],m['y']\n    w,h=m['width'],m['height']\n    if x<=pos['x']<x+w and y<=pos['y']<y+h:\n        print(f\\\"{m['name']}|{int(pos['x']-x)}\\\")\n        break\n\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|")
                if (parts.length >= 2) root.openAtCursor(parts[0], parseInt(parts[1]) || 0)
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: if (root.popupOpen && !root.userInteracting) getBrightnessProc.running = true
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        repeat: false
        onTriggered: if (!root.userInteracting) root.popupOpen = false
    }

    Process {
        id: getBrightnessProc
        command: ["sh","-c","brightnessctl -m | awk -F, '{gsub(/%/, \"\", $4); print $4; exit}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim())
                if (!isNaN(v)) root.brightness = root.clamp(v / 100, 0.01, 1)
            }
        }
    }

    Process { id: setBrightnessProc; command: ["sh","-c","true"]; running: false }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.left: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            implicitWidth: root.popupWidth
            implicitHeight: root.popupHeight
            margins.top: root.topOffset
            margins.left: root.clamp(
                root.localCursorX - root.popupWidth / 2,
                8,
                modelData.width - root.popupWidth - 8
            )
            visible: root.popupOpen && modelData.name === root.activeMonitor

            Rectangle {
                anchors.fill: parent
                color: root.colBg
                opacity: 0.92
                border.color: root.colFilled
                border.width: 1
            }

            Text {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 14
                    topMargin: 8
                }
                text: "BRT"
                font.family: "Share Tech Mono"
                font.pixelSize: 9
                font.letterSpacing: 2
                color: root.colFilled
                opacity: 0.85
            }

            Text {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 14
                    topMargin: 8
                }
                text: Math.round(root.brightness * 100) + "%"
                font.family: "Share Tech Mono"
                font.pixelSize: 9
                font.letterSpacing: 2
                color: root.colFilled
                opacity: 0.85
            }

            Row {
                id: segmentsRow
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 14
                    bottomMargin: 14
                }
                height: 28
                spacing: 2

                Repeater {
                    model: root.segments
                    Item {
                        width: (segmentsRow.width - (root.segments - 1) * segmentsRow.spacing) / root.segments
                        height: segmentsRow.height

                        property real segLevel: index / (root.segments - 1)
                        property bool filled: root.brightness >= segLevel - 0.0001
                        property real segStep: 1 / (root.segments - 1)
                        property bool active: filled && (root.brightness < segLevel + segStep - 0.0001)

                        Rectangle {
                            anchors.centerIn: parent
                            width:  parent.active ? root.segActiveW
                                  : parent.filled ? root.segFilledW
                                  :                 root.segEmptyW
                            height: parent.active ? root.segActiveH
                                  : parent.filled ? root.segFilledH
                                  :                 root.segEmptyH
                            radius: parent.filled ? 1 : 0
                            color: parent.filled ? root.colFilled : root.colEmpty

                            Behavior on width   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color   { ColorAnimation  { duration: 160 } }
                            Behavior on radius  { NumberAnimation { duration: 160 } }
                        }
                    }
                }
            }

            MouseArea {
                id: popupMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                function xToBrightness(x) {
                    var left = segmentsRow.x
                    var right = segmentsRow.x + segmentsRow.width
                    return root.clamp((x - left) / Math.max(1, right - left), 0.01, 1)
                }

                onEntered: hideTimer.stop()
                onExited: hideTimer.restart()

                onPressed: function(e) {
                    root.userInteracting = true
                    root.setBrightness(xToBrightness(e.x))
                }
                onReleased: {
                    root.userInteracting = false
                    hideTimer.restart()
                }
                onPositionChanged: function(e) {
                    if (pressed) root.setBrightness(xToBrightness(e.x))
                }
                onWheel: function(e) {
                    var step = 0.08
                    if (e.angleDelta.y > 0) root.setBrightness(root.brightness + step)
                    else                    root.setBrightness(root.brightness - step)
                    hideTimer.restart()
                }
            }
        }
    }
}
