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
        color: "#89b4fa"
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Graph {
        id: swapGraph
        label: "SWAP"
        color: "#cba6f7"
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    FileView {
        id: memInfoFile
        path: "/proc/meminfo"

        onTextChanged: {
            let text = memInfoFile.text()
            let values = {}

            let lines = text.split("\n")
            for (let i = 0; i < lines.length; i++) {
                let match = lines[i].match(/^(\w+):\s+(\d+)/)
                if (match) {
                    values[match[1]] = parseInt(match[2])
                }
            }

            // RAM: MemTotal - MemAvailable
            let memTotal = values["MemTotal"] || 0
            let memAvailable = values["MemAvailable"] || 0
            if (memTotal > 0) {
                let memUsed = memTotal - memAvailable
                memGraph.addValue(Math.round((memUsed / memTotal) * 100))
            }

            // Swap: SwapTotal - SwapFree
            let swapTotal = values["SwapTotal"] || 0
            let swapFree = values["SwapFree"] || 0
            if (swapTotal > 0) {
                let swapUsed = swapTotal - swapFree
                swapGraph.addValue(Math.round((swapUsed / swapTotal) * 100))
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: memInfoFile.reload()
    }
}
