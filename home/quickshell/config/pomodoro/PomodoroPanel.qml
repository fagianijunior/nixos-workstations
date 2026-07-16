// PomodoroPanel.qml — Painel Pomodoro no QuickShell
// Usa tomat via PomodoroManager. Sempre visível, cores por fase.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Rectangle {
    id: pomodoroPanel

    color: Qt.rgba(36/255, 39/255, 58/255, 0.7)
    radius: 8
    implicitHeight: innerLayout.implicitHeight + 12  // 6px margin top + 6px bottom

    // Cor da borda varia por fase
    property color phaseColor: {
        switch (manager.phase) {
            case "work":
            case "work-paused":   return "#f38ba8"  // red
            case "break":
            case "break-paused":  return "#a6e3a1"  // green
            case "long-break":    return "#89b4fa"  // blue
            default:              return "#6c7086"  // subtext0 (idle)
        }
    }

    border.color: phaseColor
    border.width: 1

    // ---- Data Layer ----

    PomodoroManager {
        id: manager
        onErrorOccurred: function(msg) {
            console.error("PomodoroManager error:", msg)
        }
    }

    // ---- Layout ----

    ColumnLayout {
        id: innerLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        spacing: 4

        // Header: título + status
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "🍅 Pomodoro"
                color: "#cad3f5"
                font.pixelSize: Math.max(12, Math.min(14, rootPanel.width * 0.06))
                font.bold: true
                Layout.fillWidth: true
            }

            // Tooltip / fase
            Text {
                text: manager.tooltip
                color: pomodoroPanel.phaseColor
                font.pixelSize: 9
                elide: Text.ElideRight
                Layout.fillWidth: true
                maximumLineCount: 1
            }
        }

        // Timer display
        Text {
            text: manager.statusText
            color: pomodoroPanel.phaseColor
            font.pixelSize: Math.max(14, Math.min(18, rootPanel.width * 0.08))
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Barra de progresso
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: "#313244"
            visible: manager.isActive

            Rectangle {
                width: parent.width * Math.min(1.0, manager.percentage / 100.0)
                height: parent.height
                radius: parent.radius
                color: pomodoroPanel.phaseColor

                Behavior on width {
                    NumberAnimation { duration: 300 }
                }
            }
        }

        // Controles
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // Start — só quando idle
            Button {
                visible: !manager.isActive
                text: "▶ Start"
                Layout.fillWidth: true
                implicitHeight: 24
                onClicked: manager.start()
                contentItem: Text {
                    text: parent.text
                    color: "#a6e3a1"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : "#313244"
                    border.color: "#a6e3a1"
                    border.width: 1
                    radius: 4
                }
            }

            // Pause/Resume — só quando ativo
            Button {
                visible: manager.isActive
                text: manager.isPaused ? "▶ Resume" : "⏸ Pause"
                Layout.fillWidth: true
                implicitHeight: 24
                onClicked: manager.toggle()
                contentItem: Text {
                    text: parent.text
                    color: "#fab387"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : "#313244"
                    border.color: "#fab387"
                    border.width: 1
                    radius: 4
                }
            }

            // Skip — só quando ativo
            Button {
                visible: manager.isActive
                text: "⏭ Skip"
                implicitWidth: 52
                implicitHeight: 24
                onClicked: manager.skip()
                contentItem: Text {
                    text: parent.text
                    color: "#89b4fa"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : "#313244"
                    border.color: "#89b4fa"
                    border.width: 1
                    radius: 4
                }
            }

            // Stop — só quando ativo
            Button {
                visible: manager.isActive
                text: "⏹"
                implicitWidth: 28
                implicitHeight: 24
                onClicked: manager.stop()
                contentItem: Text {
                    text: parent.text
                    color: "#f38ba8"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : "#313244"
                    border.color: "#f38ba8"
                    border.width: 1
                    radius: 4
                }
            }
        }
    }
}
