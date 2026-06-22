import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)

    Graph {
        id: memGraph
        label: "Memória"
        color: "#89b4fa" // Blue
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Graph {
        id: swapGraph
        label: "SWAP"
        color: "#cba6f7" // Mauve
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Process {
        id: memoryMonitorProcess
        command: ["fish", "-c", "free | grep -E '(Mem.|Swap)'; sleep 3"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line === "") continue

                    let vals = line.split(/\s+/)
                    if (vals.length < 3) continue

                    let type = vals[0]
                    let total = Number(vals[1])
                    let used = Number(vals[2])

                    if (total === 0) continue

                    let percent = Math.round((used / total) * 100)

                    if (type === "Mem.:") {
                        memGraph.addValue(percent)
                    } else if (type === "Swap:") {
                        swapGraph.addValue(percent)
                    }
                }

                memoryMonitorProcess.running = true
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    memGraph.label = "Mem (Erro)"
                    swapGraph.label = "Swap (Erro)"
                }
            }
        }
    }
}
