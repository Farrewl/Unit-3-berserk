import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// ═════════════════════════════════════════════════════════════════════
//   Vertical brightness bar — right edge
//   - Same interaction as VolumeBar: hover / scroll / click / drag
//   - Backlight control via brightnessctl
//   - Active screen only
// ═════════════════════════════════════════════════════════════════════

ShellRoot {
    id: root

    readonly property int segments: 30
    readonly property int hoverWidth: 65
    readonly property int barWidth: 40
    readonly property int barHeight: 420
    readonly property int rightOffset: 18
    readonly property int hideDelay: 400

    readonly property int segFilledW: 14
    readonly property int segEmptyW:  4
    readonly property int segEmptyH:  4
    readonly property int segFilledH: 3
    readonly property int segActiveW: 22
    readonly property int segActiveH: 5

    readonly property color colFilled: "#C5A253"
    readonly property color colEmpty:  "#EBE3D1"
    readonly property color colBg:     "#14100B"

    property real brightness: 0.5
    property bool userInteracting: false
    property string activeMonitor: ""

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: activeMonitorProc.running = true
    }

    Process {
        id: activeMonitorProc
        command: ["sh","-c","hyprctl cursorpos -j | python3 -c \"\nimport sys,json,subprocess\npos=json.load(sys.stdin)\nmons=json.loads(subprocess.check_output(['hyprctl','monitors','-j']))\nfor m in mons:\n    x,y=m['x'],m['y']\n    w,h=m['width'],m['height']\n    if x<=pos['x']<x+w and y<=pos['y']<y+h:\n        print(m['name'])\n        break\n\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var n = this.text.trim()
                if (n !== "" && n !== root.activeMonitor) root.activeMonitor = n
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: if (!root.userInteracting) getBrightnessProc.running = true
    }

    Process {
        id: getBrightnessProc
        command: ["sh","-c","brightnessctl -m | awk -F, '{gsub(/%/, \"\", $4); print $4; exit}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim())
                if (!isNaN(v)) root.brightness = Math.max(0.01, Math.min(1, v / 100))
            }
        }
    }

    function setBrightness(v) {
        v = Math.max(0.01, Math.min(1, v))
        root.brightness = v
        var pct = Math.max(1, Math.round(v * 100))
        setBrightnessProc.command = ["brightnessctl","set", pct + "%"]
        setBrightnessProc.running = true
    }

    Process { id: setBrightnessProc; command: ["sh","-c","true"]; running: false }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            anchors.right: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property bool isActive: modelData.name === root.activeMonitor

            property bool revealed: hoverArea.containsMouse
                                  || barMouseArea.containsMouse
                                  || barMouseArea.pressed
                                  || hideTimer.running

            implicitWidth: revealed
                ? (root.rightOffset + root.barWidth + 10)
                : root.hoverWidth
            implicitHeight: root.barHeight + 40
            margins.top: (modelData.height - implicitHeight) / 2
            visible: isActive

            Timer {
                id: hideTimer
                interval: root.hideDelay
                repeat: false
            }

            MouseArea {
                id: hoverArea
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                x: parent.width - root.hoverWidth
                y: 0
                width: root.hoverWidth
                height: parent.height
                onEntered: hideTimer.stop()
                onExited:  hideTimer.restart()
            }

            Item {
                id: barContainer
                width: root.barWidth
                height: root.barHeight
                anchors.verticalCenter: parent.verticalCenter
                x: panel.revealed
                    ? (panel.width - root.rightOffset - root.barWidth)
                    : panel.width
                opacity: panel.revealed ? 1 : 0

                Behavior on x       { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 220 } }

                Rectangle {
                    anchors.fill: parent
                    color: root.colBg
                    opacity: 0.55
                    border.color: root.colFilled
                    border.width: 1
                    radius: 8
                    clip: true
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Repeater {
                        model: root.segments
                        Item {
                            width: parent.width
                            height: (root.barHeight - 12 - (root.segments - 1) * 2) / root.segments

                            property real segLevel: 1 - (index / (root.segments - 1))
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

                                Behavior on width   { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on height  { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on color   { ColorAnimation  { duration: 220 } }
                                Behavior on radius  { NumberAnimation { duration: 220 } }
                            }
                        }
                    }
                }

                MouseArea {
                    id: barMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton

                    function yToBrightness(y) {
                        var m = 6
                        var h = height - 2 * m
                        return Math.max(0.01, Math.min(1, 1 - (y - m) / h))
                    }

                    onEntered: hideTimer.stop()
                    onExited:  hideTimer.restart()

                    onPressed: function(e) {
                        root.userInteracting = true
                        root.setBrightness(yToBrightness(e.y))
                    }
                    onReleased: root.userInteracting = false
                    onPositionChanged: function(e) {
                        if (pressed) root.setBrightness(yToBrightness(e.y))
                    }
                    onWheel: function(e) {
                        var step = 0.08
                        if (e.angleDelta.y > 0) root.setBrightness(root.brightness + step)
                        else                    root.setBrightness(root.brightness - step)
                        hideTimer.restart()
                    }
                }

                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: -16
                    text: Math.round(root.brightness * 100) + "%"
                    font.family: "Share Tech Mono"
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    color: root.colFilled
                    opacity: 0.8
                }
            }
        }
    }
}
