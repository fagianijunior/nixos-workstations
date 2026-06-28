import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)

    // GPU VRAM Usage
    Graph {
        id: gpuUsageGraph
        label: "VRAM"
        color: "#f38ba8" // Red
        valueSuffix: "%"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // GPU Temperature
    Graph {
        id: gpuTempGraph
        label: "Temp GPU"
        color: "#fab387" // Peach
        valueSuffix: "°C"
        maxValue: 100
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Process {
        id: gpuUsageProcess
        command: ["fish", "-c", "
            set GPU_DEVICE_PATH /sys/class/drm/card1/device

            if test -f \"$GPU_DEVICE_PATH/mem_info_vram_total\" -a -f \"$GPU_DEVICE_PATH/mem_info_vram_used\"
                set VRAM_TOTAL (cat \"$GPU_DEVICE_PATH/mem_info_vram_total\")
                set VRAM_USED  (cat \"$GPU_DEVICE_PATH/mem_info_vram_used\")

                if test $VRAM_TOTAL -gt 0
                    math \"($VRAM_USED * 100) / $VRAM_TOTAL\"
                else
                    echo 0
                end
            else
                echo -1
            end

            sleep 3
        "]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let usage = parseInt(this.text.trim())
                if (!isNaN(usage) && usage >= 0) {
                    gpuUsageGraph.addValue(usage)
                } else if (this.text.trim() !== "") {
                    gpuUsageGraph.label = "VRAM (Não encontrado)"
                }
                gpuUsageProcess.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    gpuUsageGraph.label = "VRAM (Erro)"
                }
            }
        }
    }

    Process {
        id: gpuTempProcess
        command: ["fish", "-c", "
            set HWMON_PATH /sys/class/drm/card1/device/hwmon/hwmon2

            if test -f \"$HWMON_PATH/temp1_input\"
                set TEMP (cat \"$HWMON_PATH/temp1_input\")
                math \"$TEMP / 1000\"
            else
                echo -1
            end

            sleep 3
        "]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let temp = parseInt(this.text.trim())
                if (!isNaN(temp) && temp >= 0) {
                    gpuTempGraph.addValue(temp)
                } else if (this.text.trim() !== "") {
                    gpuTempGraph.label = "Temp GPU (Não enc.)"
                }
                gpuTempProcess.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    gpuTempGraph.label = "Temp GPU (Erro)"
                }
            }
        }
    }
}
