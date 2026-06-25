import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./monitors"
import "./calendar"
import "./notifications"
import "./battery"
import "./taskwarrior"


PanelWindow {
    id: rootPanel
    anchors {
        top: true
        bottom: true
        right: true
    }

    property int minWidth: 200
    property int preferredWidth: 200
    property bool sensitiveData: false

    implicitWidth: 200
    color: Qt.rgba(36/255, 39/255, 58/255, 0.7) // Catppuccin Macchiato Base color with transparency

    Component.onCompleted: {
        checksensitiveDataProcess.running = true
    }

    Process {
        id: checksensitiveDataProcess
        command: ["dunstctl", "is-paused"]
        stdout: StdioCollector {
            onStreamFinished: {
                rootPanel.sensitiveData = (this.text.trim() === "true")
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                // Ignora erros, pode ser que o dunst não esteja rodando
            }
        }
    }

    Process {
        id: dunstPauseToggleProcess
        command: ["dunstctl", "set-paused", "toggle"]
        stdout: StdioCollector {
            onStreamFinished: {
                checksensitiveDataProcess.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                checksensitiveDataProcess.running = true
            }
        }
    }

    Row {
        anchors.right: parent.right
        spacing: 4
        z: 1

        Button {
            id: inhibitButton
            text: inhibitActive ? "☕" : "💤"
            property bool inhibitActive: false
            implicitWidth: 24
            implicitHeight: 24

            onClicked: {
                if (inhibitActive) {
                    cancelInhibitProcess.running = true
                } else {
                    // Inibe sleep indefinidamente (999h ~ 41 dias)
                    inhibitProcess.command = ["systemd-inhibit", "--what=sleep", "sleep", "3596400"]
                    inhibitProcess.running = true
                    inhibitActive = true
                }
            }
            contentItem: Text {
                text: inhibitButton.text
                color: "#cad3f5"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.pressed ? "#585b70" : "#313244"
                border.color: inhibitButton.inhibitActive ? "#a6e3a1" : "#6c7086"
                border.width: 1
                radius: 5
            }
        }

        Button {
            id: pauseButton
            text: rootPanel.sensitiveData ? "⊙" : "⊘"
            implicitWidth: 24
            implicitHeight: 24
            onClicked: {
                dunstPauseToggleProcess.running = true
            }
            contentItem: Text {
                text: pauseButton.text
                color: "#cad3f5"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.pressed ? "#585b70" : "#312444"
                border.color: "#6c7086"
                border.width: 1
                radius: 5
            }
        }
    }

    Process {
        id: inhibitProcess
        // command setado dinamicamente antes de rodar
        stdout: StdioCollector {
            onStreamFinished: {
                // sleep terminou (improvável, mas trata)
                inhibitButton.inhibitActive = false
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Inhibit error:", this.text.trim())
                }
                inhibitButton.inhibitActive = false
            }
        }
    }

    Process {
        id: cancelInhibitProcess
        command: ["fish", "-c", "kill $(pgrep -f 'systemd-inhibit --what=sleep') 2>/dev/null; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                inhibitButton.inhibitActive = false
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                inhibitButton.inhibitActive = false
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5

        // HOSTNAME
        Text {
            id: hostname
            text: "carregando..."
            font.pixelSize: 12
            font.bold: true
            color: "#cad3f5"
            horizontalAlignment: Text.AlignHLeft
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
        }
        Process {
            id: hostProcess
            command: ["uname", "-rn"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    hostname.text = this.text.trim()
                    hostProcess.running = false
                }
            }
        }

        // DATA E HORA
        Text {
            id: clock
            font.pixelSize: 10
            font.bold: true
            color: "#cad3f5"
            horizontalAlignment: Text.AlignHLeft
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            Timer {
                interval: 60000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    clock.text = Qt.formatDateTime(new Date(), "HH:mm - dd/MMM/yyyy")
                }
            }
        }

        // AGENDA
        CalendarPanel {
            visible: !rootPanel.sensitiveData
            panelWidth: rootPanel.width
            Layout.fillWidth: true
        }

        // MONITORES DE SISTEMA
        CpuMonitor {
            Layout.fillWidth: true
            graphHeight: Math.max(20, rootPanel.width * 0.2)
        }

        GpuMonitor {
            Layout.fillWidth: true
            graphHeight: Math.max(20, rootPanel.width * 0.2)
        }

        MemoryMonitor {
            Layout.fillWidth: true
            graphHeight: Math.max(20, rootPanel.width * 0.2)
        }

        TempMonitor {
            Layout.fillWidth: true
            graphHeight: Math.max(20, rootPanel.width * 0.2)
        }

        // BATTERY MONITORING
        BatteryGraph {
            id: batteryGraph
        }

        // TASKWARRIOR PANEL
        TaskPanel {
            id: taskPanel
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            visible: !rootPanel.sensitiveData
        }

        // DISCO
        DiskMonitor {
            Layout.fillWidth: true
        }

        // REDE
        NetworkMonitor {
            Layout.fillWidth: true
            graphHeight: Math.max(20, rootPanel.width * 0.2)
        }

        // NOTIFICAÇÕES
        NotificationPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            panelWidth: rootPanel.width
            sensitiveData: rootPanel.sensitiveData
        }
    }
}
