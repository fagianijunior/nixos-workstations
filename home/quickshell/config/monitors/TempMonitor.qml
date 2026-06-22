import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)

    Graph {
        id: tempGraph
        label: "Temp CPU"
        color: "#fab387" // Peach
        valueSuffix: "°C"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Process {
        id: tempProcess
        command: ["fish", "-c", "sensors | grep -E 'Tctl|Package id 0' | awk '{print $2}' | sed 's/+//;s/°C//' | cut -d'.' -f1 | head -n1; sleep 3"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseFloat(this.text.trim())
                tempGraph.addValue(val)
                tempProcess.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    tempGraph.label = "Temp (Erro)"
                }
            }
        }
    }
}
