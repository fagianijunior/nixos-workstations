// PomodoroManager.qml — Polling do tomat status a cada 5 segundos
// Expõe propriedades reativas para a UI

import QtQuick
import Quickshell.Io

Item {
    id: root

    // Estado atual
    property string statusText: "🍅 25:00 ⏹"
    property string tooltip: "Ready to start"
    property string phase: "idle"   // idle | work | work-paused | break | break-paused | long-break
    property double percentage: 0.0
    property bool isActive: phase !== "idle"
    property bool isPaused: phase === "work-paused" || phase === "break-paused"

    // Sinais
    signal errorOccurred(string message)

    // ---- Internal ----

    property bool _polling: false

    function refresh() {
        if (_polling) return
        _polling = true
        statusProcess.running = true
    }

    // ---- Polling ----

    Process {
        id: statusProcess
        command: ["tomat", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root._polling = false
                let raw = this.text.trim()
                if (raw === "") {
                    root.statusText = "🍅 25:00 ⏹"
                    root.tooltip = "Daemon not running"
                    root.phase = "idle"
                    root.percentage = 0.0
                    return
                }
                try {
                    let data = JSON.parse(raw)
                    root.statusText = data.text      || "🍅 25:00 ⏹"
                    root.tooltip    = data.tooltip   || ""
                    root.phase      = data.class     || "idle"
                    root.percentage = data.percentage || 0.0
                } catch (e) {
                    root.errorOccurred("Parse error: " + e)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root._polling = false
                let err = this.text.trim()
                if (err !== "") {
                    root.phase = "idle"
                    root.errorOccurred(err)
                }
            }
        }
    }

    // ---- Controles ----

    function start()  { _runControl(["tomat", "start"])  }
    function stop()   { _runControl(["tomat", "stop"])   }
    function toggle() { _runControl(["tomat", "toggle"]) }
    function skip()   { _runControl(["tomat", "skip"])   }

    function _runControl(cmd) {
        controlProcess.command = cmd
        controlProcess.running = true
    }

    Process {
        id: controlProcess
        command: ["tomat", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                Qt.callLater(function() { root.refresh() })
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                let err = this.text.trim()
                if (err !== "") root.errorOccurred(err)
                Qt.callLater(function() { root.refresh() })
            }
        }
    }

    // ---- Timer de polling ----

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
