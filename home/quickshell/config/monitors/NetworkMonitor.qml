import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root

    property int graphHeight: Math.max(20, width * 0.2)
    property string iface: ""
    property real lastRx: -1
    property real lastTx: -1

    Graph {
        id: netGraph
        label: "DOWN ↓"
        color: "#94e2d5"
        valueSuffix: " KB/s"
        maxValue: 60000
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    Graph {
        id: netGraphUpload
        label: "UP ↑"
        color: "#fab387"
        valueSuffix: " KB/s"
        maxValue: 30000
        Layout.fillWidth: true
        Layout.preferredHeight: root.graphHeight
    }

    // Detect default network interface from /proc/net/route
    FileView {
        id: routeFile
        path: "/proc/net/route"
        blockLoading: true

        onTextChanged: {
            let lines = routeFile.text().split("\n")
            for (let i = 1; i < lines.length; i++) {
                let cols = lines[i].split(/\t+/)
                // Destination 00000000 = default route
                if (cols.length >= 2 && cols[1] === "00000000") {
                    let detected = cols[0]
                    if (detected !== root.iface) {
                        root.iface = detected
                        rxFile.path = "/sys/class/net/" + root.iface + "/statistics/rx_bytes"
                        txFile.path = "/sys/class/net/" + root.iface + "/statistics/tx_bytes"
                        root.lastRx = -1
                        root.lastTx = -1
                    }
                    break
                }
            }
        }
    }

    FileView {
        id: rxFile
        path: ""
    }

    FileView {
        id: txFile
        path: ""

        onTextChanged: {
            // Process both rx and tx when tx finishes loading
            let rx = parseInt(rxFile.text())
            let tx = parseInt(txFile.text())

            if (!isNaN(rx) && !isNaN(tx)) {
                if (root.lastRx >= 0 && root.lastTx >= 0) {
                    let downKBs = Math.round((rx - root.lastRx) / 3 / 1024)
                    let upKBs = Math.round((tx - root.lastTx) / 3 / 1024)
                    netGraph.addValue(Math.max(0, downKBs))
                    netGraphUpload.addValue(Math.max(0, upKBs))
                }
                root.lastRx = rx
                root.lastTx = tx
            }
        }
    }

    Timer {
        interval: 3000
        running: root.iface !== ""
        repeat: true
        onTriggered: {
            routeFile.reload()
            rxFile.reload()
            txFile.reload()
        }
    }
}
