import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

RowLayout {
    id: root

    Layout.fillWidth: true

    Repeater {
        id: diskRepeater
        model: ListModel {
            id: diskModel
        }

        PieChart {
            label: model.mountPoint
            color: model.color
            value: model.usage / 100.0
            Layout.fillWidth: true
        }
    }

    Component.onCompleted: {
        diskMonitorProcess.running = true
    }

    Process {
        id: diskMonitorProcess
        command: ["fish", "-c", "echo \"oi\" | df -h | grep -E '^/dev/' | awk '{print $6 \":\" $5}' | sed 's/%//' | sort"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                let colors = ["#cba6f7", "#fab387", "#89b4fa", "#a6e3a1", "#f38ba8"]
                let diskData = []

                for (let i = 0; i < lines.length && i < colors.length; i++) {
                    let line = lines[i].trim()
                    if (line === "") continue

                    let parts = line.split(':')
                    if (parts.length !== 2) continue

                    let mountPoint = parts[0]
                    let usage = parseInt(parts[1])

                    if (mountPoint.startsWith("/") && !mountPoint.includes("snap") &&
                        !mountPoint.includes("loop") && mountPoint.length < 20) {
                        diskData.push({
                            mountPoint: mountPoint,
                            usage: usage,
                            color: colors[i % colors.length]
                        })
                    }
                }

                diskModel.clear()

                for (let i = 0; i < diskData.length; i++) {
                    let disk = diskData[i]
                    diskModel.append({
                        mountPoint: disk.mountPoint,
                        usage: disk.usage,
                        color: disk.color
                    })
                }
                console.log("Disk model populated with", diskData.length, "disks")

                diskTimer.start()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Disk monitor error:", this.text.trim())
                }
            }
        }
    }

    Timer {
        id: diskTimer
        interval: 600000 // 10 minutos
        running: true
        onTriggered: {
            diskMonitorProcess.running = true
        }
    }
}
