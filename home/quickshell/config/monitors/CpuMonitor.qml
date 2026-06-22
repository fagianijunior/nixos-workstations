import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)

    Graph {
        id: cpuGraph
        label: "CPU"
        color: "#a6e3a1" // Green
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Process {
        id: cpuProcess
        command: ["fish", "-c", "grep 'cpu ' /proc/stat; sleep 3; grep 'cpu ' /proc/stat"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                if (lines.length === 2) {
                    let vals1 = lines[0].split(/\s+/).slice(1).map(Number)
                    let vals2 = lines[1].split(/\s+/).slice(1).map(Number)
                    let idle1 = vals1[3], idle2 = vals2[3]
                    let total1 = vals1.reduce((a,b)=>a+b,0)
                    let total2 = vals2.reduce((a,b)=>a+b,0)
                    let totalDiff = total2 - total1
                    let idleDiff = idle2 - idle1
                    let usage = Math.round(100 * (1 - idleDiff / totalDiff))
                    cpuGraph.addValue(usage)
                }
                cpuProcess.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    cpuGraph.label = "CPU (Erro)"
                }
            }
        }
    }
}
