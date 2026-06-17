import QtQuick
import Quickshell.Io

Item {
    id: deviceDetector
    
    // Properties for device identification
    property string deviceName: ""
    property bool isDoraemon: false
    property bool isNobita: false
    property bool isPortableDevice: false
    
    // Signal emitted when device detection is complete
    signal deviceDetected(string device)
    
    // Process to get hostname for device identification
    Process {
        id: hostnameProcess
        command: ["hostname"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                let hostname = this.text.trim().toLowerCase()
                deviceDetector.deviceName = hostname
                
                // Set device-specific flags based on hostname
                deviceDetector.isDoraemon = (hostname === "doraemon")
                deviceDetector.isNobita = (hostname === "nobita")
                
                // Determine if this is a portable device
                // Doraemon is the notebook/laptop, Nobita is the desktop
                deviceDetector.isPortableDevice = deviceDetector.isDoraemon
                
                // Emit signal with detected device
                deviceDetector.deviceDetected(hostname)
                
                console.log("Device detected:", hostname, 
                           "isDoraemon:", deviceDetector.isDoraemon,
                           "isNobita:", deviceDetector.isNobita,
                           "isPortable:", deviceDetector.isPortableDevice)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("DeviceDetector error:", this.text.trim())
                    // Fallback to unknown device
                    deviceDetector.deviceName = "unknown"
                    deviceDetector.isDoraemon = false
                    deviceDetector.isNobita = false
                    deviceDetector.isPortableDevice = false
                    deviceDetector.deviceDetected("unknown")
                }
            }
        }
    }
    
    // Public functions
    function getCurrentDevice() {
        return deviceName
    }
    
    function isPortable() {
        return isPortableDevice
    }
    
    function getDeviceSpecificConfig() {
        return {
            "deviceName": deviceName,
            "isDoraemon": isDoraemon,
            "isNobita": isNobita,
            "isPortable": isPortableDevice,
            "batteryEnabled": isPortableDevice,
            "performanceMode": isNobita ? "desktop" : "laptop"
        }
    }
    
    // Force re-detection (useful for testing or manual refresh)
    function refresh() {
        hostnameProcess.running = true
    }
}