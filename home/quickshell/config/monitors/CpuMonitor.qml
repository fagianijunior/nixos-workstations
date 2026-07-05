import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property var lastCpuVals: []

    Graph {
        id: cpuGraph
        label: "CPU"
        color: "#a6e3a1"
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        blockLoading: true

        onTextChanged: {
            let firstLine = statFile.text().split("\n")[0]
            let parts = firstLine.split(/\s+/).slice(1).map(Number)
            if (root.lastCpuVals.length > 0) {
                let idle1 = root.lastCpuVals[3]
                let idle2 = parts[3]
                let total1 = root.lastCpuVals.reduce((a, b) => a + b, 0)
                let total2 = parts.reduce((a, b) => a + b, 0)
                let totalDiff = total2 - total1
                let idleDiff = idle2 - idle1
                if (totalDiff > 0) {
                    cpuGraph.addValue(Math.round(100 * (1 - idleDiff / totalDiff)))
                }
            }
            root.lastCpuVals = parts
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: statFile.reload()
    }
}
