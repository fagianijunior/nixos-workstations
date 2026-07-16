import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property double memTotalGb: 0
    property double memUsedGb: 0
    property double swapTotalGb: 0
    property double swapUsedGb: 0

    DualGraph {
        id: memSwapGraph
        label1: "MEM"
        label2: "SWAP"
        color1: "#89b4fa"
        color2: "#cba6f7"
        displayLabel1: "MEM " + root.memUsedGb.toFixed(1) + "/" + root.memTotalGb.toFixed(1) + " GB"
        displayLabel2: "SWAP " + root.swapUsedGb.toFixed(1) + "/" + root.swapTotalGb.toFixed(1) + " GB"
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

            // RAM: MemTotal - MemAvailable (values in kB)
            let memTotal = values["MemTotal"] || 0
            let memAvailable = values["MemAvailable"] || 0
            if (memTotal > 0) {
                let memUsed = memTotal - memAvailable
                root.memTotalGb = memTotal / (1024 * 1024)
                root.memUsedGb = memUsed / (1024 * 1024)
                memSwapGraph.addValue1(Math.round((memUsed / memTotal) * 100))
            }

            // Swap: SwapTotal - SwapFree (values in kB)
            let swapTotal = values["SwapTotal"] || 0
            let swapFree = values["SwapFree"] || 0
            if (swapTotal > 0) {
                let swapUsed = swapTotal - swapFree
                root.swapTotalGb = swapTotal / (1024 * 1024)
                root.swapUsedGb = swapUsed / (1024 * 1024)
                memSwapGraph.addValue2(Math.round((swapUsed / swapTotal) * 100))
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
