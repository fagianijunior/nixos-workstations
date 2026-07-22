import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQml

import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property var lastCpuVals: []
    property string hwmonPath: ""
    property int cpuTemp: 0

    Text {
        id: cpuName
        text: "carregando..."
        font.pixelSize: 10
        font.bold: true
        color: "#cad3f5"
        Layout.alignment: Qt.AlignLeft
        Layout.fillWidth: true
        elide: Text.ElideRight
    }

    // Seu FileView apontando para o cpuinfo
    FileView {
        id: cpuInfoFile
        path: "/proc/cpuinfo"
        blockLoading: true

        onTextChanged: {
            // Separa o arquivo por linhas
            let lines = cpuInfoFile.text().split("\n")
            
            // Procura pela linha que contém "model name"
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].includes("model name")) {
                    // Divide a linha no caractere ":" para separar a chave do valor
                    let parts = lines[i].split(":")
                    if (parts.length > 1) {
                        // Limpa os espaços em branco extras e joga o nome no seu Text
                        cpuName.text = parts[1].trim()
                    }
                    break // Para o loop assim que encontrar o primeiro núcleo
                }
            }
        }
    }

    DualGraph {
        id: cpuDualGraph
        label1: "CPU"
        label2: "Temp"
        color1: "#a6e3a1"
        color2: "#fab387"
        displayLabel1: "CPU " + cpuDualGraph.currentValue1.toFixed(0) + "%"
        displayLabel2: root.cpuTemp + "°C"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // CPU usage
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
                    cpuDualGraph.addValue1(Math.round(100 * (1 - idleDiff / totalDiff)))
                }
            }
            root.lastCpuVals = parts
        }
    }

    // CPU temperature — k10temp (AMD) or coretemp (Intel)
    Instantiator {
        model: ["hwmon0", "hwmon1", "hwmon2", "hwmon3", "hwmon4", "hwmon5"]

        delegate: FileView {
            id: nameFile
            path: "/sys/class/hwmon/" + modelData + "/name"
            blockLoading: true

            onTextChanged: {
                let name = nameFile.text().trim()
                if (name === "k10temp" || name === "coretemp") {
                    root.hwmonPath = "/sys/class/hwmon/" + modelData
                }
            }
        }
    }

    FileView {
        id: tempFile
        path: root.hwmonPath !== "" ? root.hwmonPath + "/temp1_input" : ""

        onTextChanged: {
            let temp = parseInt(tempFile.text())
            if (!isNaN(temp) && temp > 0) {
                root.cpuTemp = Math.round(temp / 1000)
                cpuDualGraph.addValue2(root.cpuTemp)
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            statFile.reload()
            if (root.hwmonPath !== "") tempFile.reload()
        }
    }
}
