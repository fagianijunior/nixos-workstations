import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PopupWindow {
    id: popup

    property var anchorWindow: null
    property bool inhibitActive: false
    property int inhibitHours: 0
    property int inhibitPid: -1

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow ? (anchorWindow.width / 2 - width / 2) : 0
    anchor.rect.y: anchorWindow ? (anchorWindow.height / 2 - height / 2) : 0

    width: 280
    height: inhibitActive ? 180 : 160
    visible: false
    grabFocus: true

    color: Qt.rgba(36/255, 39/255, 58/255, 0.95)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: inhibitActive ? "☕ Sleep Inibido" : "☕ Inibir Sleep"
            font.pixelSize: 14
            font.bold: true
            color: "#cad3f5"
            Layout.alignment: Qt.AlignHCenter
        }

        // Estado ativo: mostra info + botão cancelar
        ColumnLayout {
            visible: inhibitActive
            spacing: 8
            Layout.fillWidth: true

            Text {
                text: `Inibindo por ${popup.inhibitHours}h`
                font.pixelSize: 12
                color: "#a6e3a1"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: `PID: ${popup.inhibitPid}`
                font.pixelSize: 10
                color: "#a6adc8"
                Layout.alignment: Qt.AlignHCenter
            }

            Button {
                text: "Cancelar Inibição"
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                onClicked: {
                    cancelInhibitProcess.running = true
                }
                contentItem: Text {
                    text: parent.text
                    color: "#cad3f5"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.pressed ? "#f38ba8" : "#45475a"
                    border.color: "#f38ba8"
                    border.width: 1
                    radius: 5
                }
            }
        }

        // Estado inativo: input para horas
        ColumnLayout {
            visible: !inhibitActive
            spacing: 8
            Layout.fillWidth: true

            Text {
                text: "Horas para inibir sleep:"
                font.pixelSize: 11
                color: "#a6adc8"
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: hoursInput
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                placeholderText: "Ex: 2"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13
                validator: IntValidator { bottom: 1; top: 168 }
                focus: true

                color: "#cad3f5"
                placeholderTextColor: "#6c7086"

                background: Rectangle {
                    color: "#313244"
                    border.color: hoursInput.activeFocus ? "#89b4fa" : "#6c7086"
                    border.width: hoursInput.activeFocus ? 2 : 1
                    radius: 5
                }

                Keys.onReturnPressed: confirmButton.clicked()
                Keys.onEnterPressed: confirmButton.clicked()
                Keys.onEscapePressed: popup.visible = false
            }

            Button {
                id: confirmButton
                text: "Iniciar"
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                enabled: hoursInput.text.length > 0 && parseInt(hoursInput.text) > 0
                onClicked: {
                    let hours = parseInt(hoursInput.text)
                    if (hours > 0) {
                        popup.inhibitHours = hours
                        let seconds = hours * 3600
                        inhibitProcess.command = ["systemd-inhibit", "--what=sleep", "sleep", seconds.toString()]
                        inhibitProcess.running = true
                        popup.inhibitActive = true
                        popup.visible = false
                        hoursInput.text = ""
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.enabled ? "#cad3f5" : "#6c7086"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : (parent.enabled ? "#45475a" : "#313244")
                    border.color: parent.enabled ? "#a6e3a1" : "#6c7086"
                    border.width: 1
                    radius: 5
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible && !inhibitActive) {
            hoursInput.text = ""
            hoursInput.forceActiveFocus()
        }
    }

    Process {
        id: inhibitProcess
        // command é setado dinamicamente antes de rodar

        stdout: StdioCollector {
            onStreamFinished: {
                // sleep terminou normalmente
                popup.inhibitActive = false
                popup.inhibitPid = -1
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Inhibit error:", this.text.trim())
                }
                popup.inhibitActive = false
                popup.inhibitPid = -1
            }
        }

        onRunningChanged: {
            if (running) {
                // Busca o PID do processo de inibição
                getPidProcess.running = true
            }
        }
    }

    Process {
        id: getPidProcess
        command: ["fish", "-c", "sleep 0.5; pgrep -f 'systemd-inhibit --what=sleep' | head -1"]

        stdout: StdioCollector {
            onStreamFinished: {
                let pid = parseInt(this.text.trim())
                if (!isNaN(pid) && pid > 0) {
                    popup.inhibitPid = pid
                }
            }
        }
    }

    Process {
        id: cancelInhibitProcess
        command: ["fish", "-c", `kill $(pgrep -f 'systemd-inhibit --what=sleep')`]

        stdout: StdioCollector {
            onStreamFinished: {
                popup.inhibitActive = false
                popup.inhibitPid = -1
                popup.visible = false
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                // Mesmo em caso de erro, reseta o estado
                popup.inhibitActive = false
                popup.inhibitPid = -1
                popup.visible = false
            }
        }
    }
}
