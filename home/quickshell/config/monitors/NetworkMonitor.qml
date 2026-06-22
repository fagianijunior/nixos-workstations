import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)

    Graph {
        id: netGraph
        label: "DOWN ↓"
        color: "#94e2d5" // Teal
        valueSuffix: " KB/s"
        maxValue: 60000
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Graph {
        id: netGraphUpload
        label: "UP ↑"
        color: "#fab387" // Peach
        valueSuffix: " KB/s"
        maxValue: 30000
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Process {
        id: networkMonitorProcess
        running: true
        command: ["fish", "-c", "
            set IFACE (ip route | grep '^default' | awk '{print $5; exit}')
            set RX1 (cat /sys/class/net/$IFACE/statistics/rx_bytes)
            set TX1 (cat /sys/class/net/$IFACE/statistics/tx_bytes)
            sleep 3
            set RX2 (cat /sys/class/net/$IFACE/statistics/rx_bytes)
            set TX2 (cat /sys/class/net/$IFACE/statistics/tx_bytes)
            set DOWN (math \"($RX2 - $RX1) / 3 / 1024\")
            set UP   (math \"($TX2 - $TX1) / 3 / 1024\")
            echo \"DOWN:$DOWN\"
            echo \"UP:$UP\"
        "]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line === "") continue

                    let parts = line.split(':')
                    if (parts.length !== 2) continue

                    let type = parts[0]
                    let value = parseInt(parts[1])

                    if (type === "DOWN") {
                        netGraph.addValue(value)
                    } else if (type === "UP") {
                        netGraphUpload.addValue(value)
                    }
                }

                networkMonitorProcess.running = true
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    netGraph.label = "Down (Erro)"
                    netGraphUpload.label = "Up (Erro)"
                }
            }
        }
    }
}
