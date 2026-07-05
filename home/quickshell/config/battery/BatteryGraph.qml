import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"
import "../utils"

Graph {
    id: batteryGraph

    // Battery-specific properties
    property bool isPortableDevice: false
    property int warningThreshold: 20
    property int criticalThreshold: 10
    property int currentBatteryLevel: 0
    property bool isCharging: false
    property string batteryPath: ""

    // Configure the base Graph component for battery display
    label: "Bateria"
    valueSuffix: "%"
    maxValue: 100
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(60, parent.width * 0.3)

    // Device detector for conditional display
    DeviceDetector {
        id: deviceDetector

        onDeviceDetected: function(device) {
            batteryGraph.isPortableDevice = deviceDetector.isPortableDevice
            if (batteryGraph.isPortableDevice) {
                batteryGraph.visible = true
            } else {
                batteryGraph.visible = false
            }
        }
    }

    // Discover battery path by checking common power_supply names
    Repeater {
        model: ["BAT0", "BAT1", "BAT2", "BATT", "battery"]

        FileView {
            path: "/sys/class/power_supply/" + modelData + "/type"
            blockLoading: true

            onTextChanged: {
                if (this.text().trim() === "Battery" && batteryGraph.batteryPath === "") {
                    batteryGraph.batteryPath = "/sys/class/power_supply/" + modelData
                }
            }
        }
    }

    FileView {
        id: capacityFile
        path: batteryGraph.batteryPath !== "" ? batteryGraph.batteryPath + "/capacity" : ""

        onTextChanged: {
            let level = parseInt(capacityFile.text())
            if (!isNaN(level) && level >= 0 && level <= 100) {
                batteryGraph.currentBatteryLevel = level
                batteryGraph.addValue(level)
                batteryGraph.color = getBatteryColor(level, batteryGraph.isCharging)
            }
        }
    }

    FileView {
        id: statusFile
        path: batteryGraph.batteryPath !== "" ? batteryGraph.batteryPath + "/status" : ""

        onTextChanged: {
            let status = statusFile.text().trim()
            batteryGraph.isCharging = (status === "Charging")

            if (batteryGraph.isCharging) {
                batteryGraph.label = "Bateria ⚡"
            } else {
                batteryGraph.label = "Bateria"
            }

            batteryGraph.color = getBatteryColor(batteryGraph.currentBatteryLevel, batteryGraph.isCharging)
        }
    }

    Timer {
        interval: 30000
        running: batteryGraph.isPortableDevice && batteryGraph.batteryPath !== ""
        repeat: true
        onTriggered: {
            capacityFile.reload()
            statusFile.reload()
        }
    }

    // Function to determine battery color based on level and charging status
    function getBatteryColor(level, charging) {
        if (charging) {
            return "#a6e3a1" // Green when charging
        } else if (level <= criticalThreshold) {
            return "#f38ba8" // Red for critical
        } else if (level <= warningThreshold) {
            return "#fab387" // Peach for warning
        } else {
            return "#89b4fa" // Blue for normal
        }
    }

    // Initialize visibility based on device type
    Component.onCompleted: {
        batteryGraph.visible = false
    }
}
