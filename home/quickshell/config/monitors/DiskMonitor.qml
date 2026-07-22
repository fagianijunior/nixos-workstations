import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

RowLayout {
    id: root

    Layout.fillWidth: true
    spacing: 2
    clip: true

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
            Layout.maximumWidth: Math.max(40, (root.width - (diskRepeater.count - 1) * root.spacing) / Math.max(1, diskRepeater.count))
        }
    }

    Component.onCompleted: {
        diskMonitorProcess.running = true
    }

    Process {
        id: diskMonitorProcess
        command: ["df", "--output=target,pcent", "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs", "-x", "efivarfs"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n').slice(1) // skip header
                let colors = ["#cba6f7", "#fab387", "#89b4fa", "#a6e3a1", "#f38ba8"]
                let diskData = []

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line === "") continue

                    let match = line.match(/^(.+?)\s+(\d+)%$/)
                    if (!match) continue

                    let mountPoint = match[1].trim()
                    let usage = parseInt(match[2])

                    if (mountPoint.startsWith("/") && !mountPoint.includes("snap") &&
                        !mountPoint.includes("loop") && mountPoint.length < 20) {
                        diskData.push({
                            mountPoint: mountPoint,
                            usage: usage,
                            color: colors[diskData.length % colors.length]
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

                diskTimer.start()
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
