import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root

    property int panelWidth: 200

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        Text {
            text: "Agenda"
            font.pixelSize: Math.max(14, Math.min(18, root.panelWidth * 0.07))
            font.bold: true
            color: "#cad3f5"
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.Left
            Layout.fillWidth: true
        }

        Button {
            id: refreshEventsButton
            text: "↻"
            implicitWidth: 24
            implicitHeight: 24
            onClicked: {
                calendarProcess.running = true
            }
            contentItem: Text {
                text: refreshEventsButton.text
                color: "#cad3f5"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.pressed ? "#585b70" : "#313244"
                border.color: "#6c7086"
                border.width: 1
                radius: 5
            }
        }
    }

    Component {
        id: styledToolTip
        ToolTip {
            id: toolTip
            background: Rectangle {
                color: "#24273a"
                border.color: "#89b4fa"
                border.width: 1
                radius: 4
            }
            contentItem: Text {
                text: toolTip.text
                color: "#cad3f5"
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                padding: 8
            }
        }
    }

    ListView {
        id: eventList
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        clip: true

        model: ListModel {
            id: eventModel
        }

        delegate: Rectangle {
            width: eventList.width
            height: eventContent.height + 20
            color: Qt.rgba(0.2, 0.2, 0.2, 0.7)
            border.color: "#555555"
            border.width: 1
            radius: 8

            ColumnLayout {
                id: eventContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                spacing: 5

                Text {
                    id: eventSummaryText
                    text: model.summary
                    color: "#cad3f5"
                    font.pixelSize: Math.max(12, Math.min(14, root.panelWidth * 0.052))
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 1

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        visible: eventSummaryText.truncated

                        property var tooltip: styledToolTip.createObject(this, { text: model.summary })

                        onEntered: tooltip.open()
                        onExited: tooltip.close()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: Qt.formatDateTime(new Date(model.start), "hh:mm")
                        color: "#a6adc8"
                        font.pixelSize: 10
                    }
                    Text {
                        text: model.hangoutLink ? "Entrar na reunião" : ""
                        color: "#89b4fa"
                        font.underline: false
                        visible: model.hangoutLink
                        font.pixelSize: 10
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Qt.openUrlExternally(model.hangoutLink + "?authuser=1")
                        }
                    }
                }
            }
        }
        spacing: 5

        Text {
            id: noEventsText
            text: "Nenhum evento para hoje."
            color: "#a6adc8"
            visible: eventModel.count === 0 && !calendarErrorText.visible
            anchors.centerIn: parent
            font.pixelSize: Math.max(8, Math.min(18, root.panelWidth * 0.07))
        }
    }

    Text {
        id: calendarErrorText
        text: "Erro ao carregar eventos."
        color: "#f38ba8"
        visible: false
        Layout.alignment: Qt.AlignHCenter
    }

    Process {
        id: calendarProcess
        command: ["fish", "-c", "$HOME/.local/bin/python3-google $HOME/.config/quickshell/get_events.py"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let events = JSON.parse(this.text)
                    eventModel.clear()
                    calendarErrorText.visible = false
                    if (events.error) {
                        calendarErrorText.text = "Erro: " + events.error
                        calendarErrorText.visible = true
                        return
                    }
                    for (var i = 0; i < events.length; i++) {
                        eventModel.append(events[i])
                    }
                } catch (e) {
                    calendarErrorText.text = "Erro ao processar eventos."
                    calendarErrorText.visible = true
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    calendarErrorText.text = "Erro no script: " + this.text
                    calendarErrorText.visible = true
                }
            }
        }
    }
}
