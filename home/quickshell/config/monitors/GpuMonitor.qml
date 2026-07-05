import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property string gpuHwmonPath: ""

    // GPU VRAM Usage
    Graph {
        id: gpuUsageGraph
        label: "VRAM"
        color: "#f38ba8"
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // GPU Temperature
    Graph {
        id: gpuTempGraph
        label: "Temp GPU"
        color: "#fab387"
        valueSuffix: "°C"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // Discover amdgpu hwmon path dynamically
    Repeater {
        model: ["hwmon0", "hwmon1", "hwmon2", "hwmon3", "hwmon4", "hwmon5"]

        FileView {
            path: "/sys/class/hwmon/" + modelData + "/name"
            blockLoading: true

            onTextChanged: {
                if (this.text().trim() === "amdgpu") {
                    root.gpuHwmonPath = "/sys/class/hwmon/" + modelData
                }
            }
        }
    }

    FileView {
        id: vramTotalFile
        path: root.gpuHwmonPath !== "" ? root.gpuHwmonPath + "/device/mem_info_vram_total" : ""
        blockLoading: true
    }

    FileView {
        id: vramUsedFile
        path: root.gpuHwmonPath !== "" ? root.gpuHwmonPath + "/device/mem_info_vram_used" : ""

        onTextChanged: {
            let total = parseInt(vramTotalFile.text())
            let used = parseInt(vramUsedFile.text())
            if (!isNaN(total) && !isNaN(used) && total > 0) {
                gpuUsageGraph.addValue(Math.round((used * 100) / total))
            }
        }
    }

    FileView {
        id: gpuTempFile
        path: root.gpuHwmonPath !== "" ? root.gpuHwmonPath + "/temp1_input" : ""

        onTextChanged: {
            let temp = parseInt(gpuTempFile.text())
            if (!isNaN(temp) && temp > 0) {
                gpuTempGraph.addValue(Math.round(temp / 1000))
            }
        }
    }

    Timer {
        interval: 3000
        running: root.gpuHwmonPath !== ""
        repeat: true
        onTriggered: {
            vramTotalFile.reload()
            vramUsedFile.reload()
            gpuTempFile.reload()
        }
    }
}
