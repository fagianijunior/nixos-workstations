// TimePanel.qml — Painel de Tempo (Taskwarrior + Timewarrior)
// Exibe métricas de tempo diário e semanal via TimeDataManager.

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: timePanel

    color:  Qt.rgba(36/255, 39/255, 58/255, 0.7)
    radius: 8
    implicitHeight: innerLayout.implicitHeight + 12

    // ---- Data layer ----

    TimeDataManager {
        id: timeData
    }

    // ---- Timer do cronômetro da tarefa ativa (1 s) ----
    property int activeElapsed: timeData.activeTask ? (timeData.activeTask.elapsed_seconds || 0) : 0

    Timer {
        id: activeTimer
        interval: 1000
        running:  timeData.activeTask !== null
        repeat:   true
        onTriggered: timePanel.activeElapsed += 1
    }

    // Quando os dados atualizam, recarrega o elapsed base da tarefa ativa
    Connections {
        target: timeData
        function onDataReady() {
            timePanel.activeElapsed = timeData.activeTask
                ? (timeData.activeTask.elapsed_seconds || 0)
                : 0
        }
    }

    // ---- Helpers de formatação ----

    function fmtHM(seconds) {
        if (seconds <= 0) return "0m"
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return h + "h " + (m > 0 ? m + "m" : "")
        return m + "m"
    }

    function fmtHMS(seconds) {
        if (seconds < 0) seconds = 0
        var h  = Math.floor(seconds / 3600)
        var m  = Math.floor((seconds % 3600) / 60)
        var s  = seconds % 60
        var hh = h < 10 ? "0" + h : "" + h
        var mm = m < 10 ? "0" + m : "" + m
        var ss = s < 10 ? "0" + s : "" + s
        return hh + ":" + mm + ":" + ss
    }

    function barColor(type) {
        if (type === "work")     return "#89b4fa"   // azul
        if (type === "personal") return "#a6e3a1"   // verde
        return "#6c7086"                            // cinza
    }

    property int todayTotal: timeData.todayWorkSeconds + timeData.todayPersonalSeconds + timeData.todayOtherSeconds

    // ---- Layout ----

    ColumnLayout {
        id: innerLayout
        anchors {
            left:   parent.left
            right:  parent.right
            top:    parent.top
            margins: 6
        }
        spacing: 6

        // === HEADER ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text:           "Tempo"
                color:          "#cad3f5"
                font.pixelSize: 14
                font.bold:      true
                Layout.fillWidth: true
            }

            Text {
                visible:        timeData.isLoading
                text:           "…"
                color:          "#a6adc8"
                font.pixelSize: 11
            }

            Text {
                visible:        !timeData.isLoading && timeData.errorMessage !== ""
                text:           "⚠"
                color:          "#f38ba8"
                font.pixelSize: 11
                ToolTip.visible: hovered
                ToolTip.text:   timeData.errorMessage
                MouseArea { anchors.fill: parent; hoverEnabled: true }
            }

            Text {
                visible:        timeData.lastUpdated !== ""
                text:           timeData.lastUpdated
                color:          "#6c7086"
                font.pixelSize: 9
            }

            Button {
                id: refreshBtn
                text: "↻"
                implicitWidth:  24
                implicitHeight: 24
                onClicked: timeData.refresh()
                contentItem: Text {
                    text:                refreshBtn.text
                    color:               "#cad3f5"
                    font.pixelSize:      16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color:        parent.pressed ? "#585b70" : "#313244"
                    border.color: "#6c7086"
                    border.width: 1
                    radius:       5
                }
            }
        }

        // === TAREFA ATIVA ===
        Rectangle {
            visible:          timeData.activeTask !== null
            Layout.fillWidth: true
            color:            Qt.rgba(0.34, 0.45, 0.98, 0.15)
            radius:           5
            implicitHeight:   activeTaskLayout.implicitHeight + 8

            RowLayout {
                id: activeTaskLayout
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top
                    margins: 6
                }
                spacing: 6

                Text {
                    text:           "▶"
                    color:          "#89b4fa"
                    font.pixelSize: 10
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text:             timeData.activeTask ? timeData.activeTask.description : ""
                        color:            "#cad3f5"
                        font.pixelSize:   10
                        font.bold:        true
                        elide:            Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible:        timeData.activeTask && timeData.activeTask.project !== ""
                        text:           timeData.activeTask ? timeData.activeTask.project : ""
                        color:          "#a6adc8"
                        font.pixelSize: 9
                    }
                }

                Text {
                    text:           fmtHMS(timePanel.activeElapsed)
                    color:          "#a6e3a1"
                    font.pixelSize: 11
                    font.bold:      true
                    font.family:    "monospace"
                }
            }
        }

        // === RESUMO HOJE ===
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text:                "Hoje"
                color:               "#a6adc8"
                font.pixelSize:      9
                font.bold:           true
                font.capitalization: Font.AllUppercase
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 4
                    Rectangle { width: 8; height: 8; radius: 2; color: "#89b4fa" }
                    Text {
                        text:           "Trabalho: " + fmtHM(timeData.todayWorkSeconds)
                        color:          "#cad3f5"
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    spacing: 4
                    Rectangle { width: 8; height: 8; radius: 2; color: "#a6e3a1" }
                    Text {
                        text:           "Pessoal: " + fmtHM(timeData.todayPersonalSeconds)
                        color:          "#cad3f5"
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                visible:        timePanel.todayTotal > 0
                text:           "Total: " + fmtHM(timePanel.todayTotal)
                color:          "#6c7086"
                font.pixelSize: 9
            }
        }

        // === BREAKDOWN POR PROJETO ===
        ColumnLayout {
            visible:          timeData.byProject && timeData.byProject.length > 0
            Layout.fillWidth: true
            spacing: 3

            Text {
                text:                "Por Projeto"
                color:               "#a6adc8"
                font.pixelSize:      9
                font.bold:           true
                font.capitalization: Font.AllUppercase
            }

            Repeater {
                model: timeData.byProject

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text:                  modelData.project || "—"
                        color:                 "#cad3f5"
                        font.pixelSize:        10
                        elide:                 Text.ElideRight
                        Layout.preferredWidth: 70
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height:           6
                        radius:           3
                        color:            "#313244"

                        Rectangle {
                            width:  timePanel.todayTotal > 0
                                    ? Math.max(4, parent.width * modelData.seconds / timePanel.todayTotal)
                                    : 0
                            height: parent.height
                            radius: parent.radius
                            color:  barColor(modelData.type)
                        }
                    }

                    Text {
                        text:                  fmtHM(modelData.seconds)
                        color:                 "#a6adc8"
                        font.pixelSize:        9
                        Layout.preferredWidth: 36
                        horizontalAlignment:   Text.AlignRight
                    }
                }
            }
        }

        // === SEMANA ===
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text:                "Semana"
                color:               "#a6adc8"
                font.pixelSize:      9
                font.bold:           true
                font.capitalization: Font.AllUppercase
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: timeData.weekData

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        property bool isToday: modelData.date === Qt.formatDate(new Date(), "yyyy-MM-dd")
                        property int  dayTotal: (modelData.work_seconds || 0) + (modelData.personal_seconds || 0)

                        Item {
                            Layout.fillWidth: true
                            height:           40

                            Rectangle {
                                anchors.fill:  parent
                                radius:        3
                                color:         "#313244"
                                border.color:  parent.parent.isToday ? "#89b4fa" : "transparent"
                                border.width:  parent.parent.isToday ? 1 : 0
                            }

                            property int weekMax: {
                                var mx = 1
                                for (var i = 0; i < timeData.weekData.length; i++) {
                                    var d = timeData.weekData[i]
                                    var t = (d.work_seconds || 0) + (d.personal_seconds || 0)
                                    if (t > mx) mx = t
                                }
                                return mx
                            }

                            property int   dayTotalLocal: (modelData.work_seconds || 0) + (modelData.personal_seconds || 0)
                            property real  fillRatio:     dayTotalLocal / weekMax

                            // Segmento work (azul) — base
                            Rectangle {
                                anchors.bottom:  parent.bottom
                                anchors.left:    parent.left
                                anchors.right:   parent.right
                                anchors.margins: 2
                                height: parent.dayTotalLocal > 0
                                        ? Math.max(0, (parent.height - 4) * parent.fillRatio
                                          * (modelData.work_seconds || 0) / parent.dayTotalLocal)
                                        : 0
                                radius: 2
                                color:  "#89b4fa"
                            }

                            // Segmento personal (verde) — topo
                            Rectangle {
                                anchors.bottom:  parent.bottom
                                anchors.left:    parent.left
                                anchors.right:   parent.right
                                anchors.margins: 2

                                property int workH: parent.dayTotalLocal > 0
                                    ? Math.max(0, Math.round((parent.height - 4) * parent.fillRatio
                                      * (modelData.work_seconds || 0) / parent.dayTotalLocal))
                                    : 0

                                anchors.bottomMargin: 2 + workH
                                height: parent.dayTotalLocal > 0
                                        ? Math.max(0, (parent.height - 4) * parent.fillRatio
                                          * (modelData.personal_seconds || 0) / parent.dayTotalLocal)
                                        : 0
                                radius: 2
                                color:  "#a6e3a1"
                            }
                        }

                        Text {
                            text:             modelData.label
                            color:            parent.isToday ? "#89b4fa" : "#6c7086"
                            font.pixelSize:   8
                            font.bold:        parent.isToday
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
