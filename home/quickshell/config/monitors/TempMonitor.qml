import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property string hwmonPath: ""

    Graph {
        id: tempGraph
        label: "Temp CPU"
        color: "#fab387"
        valueSuffix: "°C"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // Try known hwmon paths for CPU temp (k10temp for AMD, coretemp for Intel)
    // hwmon numbers can change between boots, so we check multiple
    Repeater {
        model: ["hwmon0", "hwmon1", "hwmon2", "hwmon3", "hwmon4", "hwmon5"]

        FileView {
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
                tempGraph.addValue(Math.round(temp / 1000))
            }
        }
    }

    Timer {
        interval: 3000
        running: root.hwmonPath !== ""
        repeat: true
        onTriggered: tempFile.reload()
    }
}
