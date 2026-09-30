import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../settings"

ShellRoot {
    id: root

    property bool mediaPlaying: false
    property bool enabled: false
    property var levels: Array(128).fill(0)

    readonly property int barCount: 128
    readonly property int visualizerHeight: Settings.s(160)
    readonly property bool shouldRun: enabled && mediaPlaying

    function updateLevels(frame) {
        var values = frame.trim().split(";")
        if (values.length < barCount)
            return

        var next = []
        for (var index = 0; index < barCount; index++) {
            var sample = Number(values[index]) / 100
            sample = Math.max(0, Math.min(1, sample))
            next.push(levels[index] * 0.55 + sample * 0.45)
        }
        levels = next
    }

    function clearLevels() {
        levels = Array(barCount).fill(0)
    }

    Process {
        command: ["sh", "-c", "\"$HOME/.config/quickshell/scripts/visualizer_toggle.sh\" raw"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.enabled = this.text.trim() === "on"
        }
    }

    Process {
        id: cava
        command: ["cava", "-p", Qt.resolvedUrl("../scripts/cava-visualizer.conf").toString().replace("file://", "")]
        running: root.shouldRun
        stdout: SplitParser {
            onRead: data => root.updateLevels(data)
        }
    }

    onShouldRunChanged: {
        if (!shouldRun)
            clearLevels()
    }

    IpcHandler {
        target: "visualizer"
        function setEnabled(value: bool): void {
            root.enabled = value
        }
        function toggle(): void {
            root.enabled = !root.enabled
        }
    }

    Variants {
        model: root.shouldRun ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            implicitWidth: modelData.width
            implicitHeight: root.visualizerHeight
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Canvas {
                id: spectrum
                anchors.fill: parent
                renderTarget: Canvas.Image
                antialiasing: false

                onPaint: {
                    var context = getContext("2d")
                    context.clearRect(0, 0, width, height)

                    var barWidth = Math.max(2, Math.floor(width / root.barCount) - 2)
                    var gap = Math.max(1, Math.floor((width - barWidth * root.barCount) / (root.barCount - 1)))
                    var usedWidth = barWidth * root.barCount + gap * (root.barCount - 1)
                    var offset = Math.floor((width - usedWidth) / 2)

                    context.fillStyle = Qt.rgba(11 / 255, 10 / 255, 9 / 255, 0.16)
                    context.fillRect(0, height - 2, width, 2)

                    for (var index = 0; index < root.barCount; index++) {
                        var level = root.levels[index] || 0
                        var barHeight = Math.max(2, Math.round(level * (height - 10)))
                        var x = offset + index * (barWidth + gap)
                        var y = height - barHeight

                        context.fillStyle = Qt.rgba(200 / 255, 184 / 255, 154 / 255, 0.84)
                        context.fillRect(x, y, barWidth, barHeight)
                    }
                }

                Connections {
                    target: root
                    function onLevelsChanged() {
                        spectrum.requestPaint()
                    }
                }
            }
        }
    }
}
