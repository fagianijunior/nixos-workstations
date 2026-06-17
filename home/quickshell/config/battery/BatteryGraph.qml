import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell.Io
import "../" // Import parent directory for Graph.qml
import "../utils" // Import DeviceDetector

Graph {
    id: batteryGraph
    
    // Battery-specific properties
    property bool isPortableDevice: false
    property int warningThreshold: 20
    property int criticalThreshold: 10
    property int currentBatteryLevel: 0
    property bool isCharging: false
    
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
            console.log("BatteryGraph: Device detected -", device, "isPortable:", batteryGraph.isPortableDevice)
            
            // Only start battery monitoring if this is a portable device
            if (batteryGraph.isPortableDevice) {
                batteryGraph.visible = true
                batteryMonitorProcess.running = true
            } else {
                batteryGraph.visible = false
                console.log("BatteryGraph: Hidden on non-portable device")
            }
        }
    }
    
    // Battery monitoring process
    Process {
        id: batteryMonitorProcess
    // command: ["fish", "-c", "
    //     set LEVEL -1
    //     set STATUS Unknown

    //     for ps in /sys/class/power_supply/*
    //         if test -f \"$ps/type\"; and test (cat \"$ps/type\") = Battery
    //             if test -f \"$ps/capacity\"
    //                 set LEVEL (cat \"$ps/capacity\")
    //             end
    // 
    //             if test -f \"$ps/status\"
    //                 set STATUS (cat \"$ps/status\")
    //             end
    //             break
    //         end
    //     end
    // 
    //     echo \"LEVEL=$LEVEL STATUS=$STATUS\"
    //     sleep 30
    // "]


        command: ["fish", "-c", "
            set BATTERY_PATH \"\"

            for ps in /sys/class/power_supply/*
                if test -f \"$ps/type\"; and test (cat \"$ps/type\") = Battery
                    set BATTERY_PATH $ps
                    break
                end
            end

            if test -z \"$BATTERY_PATH\"
                echo \"ERROR:No battery found\"
                exit 1
            end

            if not test -f \"$BATTERY_PATH/capacity\"
                echo \"ERROR:Cannot read battery capacity\"
                exit 1
            end

            set CAPACITY (cat \"$BATTERY_PATH/capacity\")

            set STATUS Unknown
            if test -f \"$BATTERY_PATH/status\"
                set STATUS (cat \"$BATTERY_PATH/status\")
            end

            echo \"LEVEL:$CAPACITY\"
            echo \"STATUS:$STATUS\"

            sleep 30
        "]
        running: false // Will be started by device detector
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                let batteryLevel = 0
                let chargingStatus = "Unknown"
                
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line.startsWith("LEVEL:")) {
                        batteryLevel = parseInt(line.split(':')[1])
                    } else if (line.startsWith("STATUS:")) {
                        chargingStatus = line.split(':')[1]
                    } else if (line.startsWith("ERROR:")) {
                        console.error("Battery monitoring error:", line)
                        batteryGraph.label = "Bateria (Erro)"
                        batteryMonitorProcess.running = true // Retry
                        return
                    }
                }
                
                // Update battery state
                batteryGraph.currentBatteryLevel = batteryLevel
                batteryGraph.isCharging = (chargingStatus === "Charging")
                
                // Update the graph with new battery level
                batteryGraph.addValue(batteryLevel)
                
                // Update color based on battery level and charging status
                batteryGraph.color = getBatteryColor(batteryLevel, batteryGraph.isCharging)
                
                // Update label to show charging status
                if (batteryGraph.isCharging) {
                    batteryGraph.label = "Bateria ⚡"
                } else {
                    batteryGraph.label = "Bateria"
                }
                
                console.log("Battery updated:", batteryLevel + "%", chargingStatus, "Color:", batteryGraph.color)
                
                // Continue monitoring
                batteryMonitorProcess.running = true
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Battery process stderr:", this.text.trim())
                    batteryGraph.label = "Bateria (Erro)"
                    // Retry after error
                    batteryMonitorProcess.running = true
                }
            }
        }
    }
    
    // Function to determine battery color based on level and charging status
    function getBatteryColor(level, charging) {
        // Catppuccin Macchiato colors
        if (charging) {
            return "#a6e3a1" // Green when charging
        } else if (level <= criticalThreshold) {
            return "#f38ba8" // Red for critical level
        } else if (level <= warningThreshold) {
            return "#fab387" // Peach for warning level
        } else {
            return "#89b4fa" // Blue for normal level
        }
    }
    
    // Public function to update battery level (for testing)
    function updateBatteryLevel() {
        if (batteryGraph.isPortableDevice && !batteryMonitorProcess.running) {
            batteryMonitorProcess.running = true
        }
    }
    
    // Initialize visibility based on device type
    Component.onCompleted: {
        // Initially hidden until device detection completes
        batteryGraph.visible = false
        console.log("BatteryGraph: Component completed, waiting for device detection")
    }
}