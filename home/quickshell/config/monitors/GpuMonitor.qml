import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property string gpuHwmonPath: ""
    property double vramTotalGb: 0
    property double vramUsedGb: 0
    property int gpuTemp: 0

    Text {
        id: gpuName
        text: "carregando..."
        font.pixelSize: 10
        font.bold: true
        color: "#cad3f5"
        Layout.alignment: Qt.AlignLeft
    }

    FileView {
        id: amdGpuFile
        // TO FIX
        path: "/home/terabytes/.gpu_name"
        blockLoading: true

        onTextChanged: {
            let rawText = amdGpuFile.text().trim()
            
                gpuName.text = rawText
        }
    }
    // GPU Usage + Temperature (dual graph)
    DualGraph {
        id: gpuDualGraph
        label1: "GPU"
        label2: "Temp"
        color1: "#a6e3a1"
        color2: "#fab387"
        displayLabel1: "GPU " + gpuDualGraph.currentValue1.toFixed(0) + "%"
        displayLabel2: root.gpuTemp + "°C"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // VRAM usage graph
    Graph {
        id: vramChart
        label: "VRAM " + root.vramUsedGb.toFixed(1) + "/" + root.vramTotalGb.toFixed(1) + " GB"
        color: "#f38ba8"
        labelColor: "#f38ba8"
        valueSuffix: "%"
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
        id: gpuBusyFile
        path: root.gpuHwmonPath !== "" ? root.gpuHwmonPath + "/device/gpu_busy_percent" : ""

        onTextChanged: {
            let busy = parseInt(gpuBusyFile.text())
            if (!isNaN(busy)) {
                gpuDualGraph.addValue1(busy)
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
                root.vramTotalGb = total / (1024 * 1024 * 1024)
                root.vramUsedGb = used / (1024 * 1024 * 1024)
                vramChart.addValue(Math.round((used * 100) / total))
            }
        }
    }

    FileView {
        id: gpuTempFile
        path: root.gpuHwmonPath !== "" ? root.gpuHwmonPath + "/temp1_input" : ""

        onTextChanged: {
            let temp = parseInt(gpuTempFile.text())
            if (!isNaN(temp) && temp > 0) {
                root.gpuTemp = Math.round(temp / 1000)
                gpuDualGraph.addValue2(root.gpuTemp)
            }
        }
    }

    Timer {
        interval: 3000
        running: root.gpuHwmonPath !== ""
        repeat: true
        onTriggered: {
            gpuBusyFile.reload()
            vramTotalFile.reload()
            vramUsedFile.reload()
            gpuTempFile.reload()
        }
    }
}
