import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "../filters"
import "../colors"
import "../interaction"

ColumnLayout {
    id: root

    property int panelWidth: 200
    property bool sensitiveData: false

    // Notification filter for controlling which notifications are displayed
    NotificationFilter {
        id: notificationFilter
    }

    // Border color manager for notification styling
    BorderColorManager {
        id: borderColorManager
    }

    // Click redirect handler for notification interactions
    ClickRedirectHandler {
        id: clickRedirectHandler

        onRedirectFailed: function(appName, error) {
            console.error("Redirect failed for", appName, ":", error)
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

    // TÍTULO NOTIFICAÇÕES
    RowLayout {
        visible: !root.sensitiveData
        spacing: 10
        Layout.fillWidth: true

        Text {
            text: "Notificações"
            font.pixelSize: Math.max(14, Math.min(18, root.panelWidth * 0.07))
            font.bold: true
            color: "#cad3f5"
            horizontalAlignment: Text.Left
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Button {
            id: refreshButton
            text: "↻"
            implicitWidth: 24
            implicitHeight: 24
            onClicked: {
                notificationProcess.running = true
            }
            background: Rectangle {
                color: parent.pressed ? "#585b70" : "#313244"
                border.color: "#6c7086"
                border.width: 1
                radius: 5
            }
            contentItem: Text {
                text: refreshButton.text
                color: "#cad3f5"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // LISTA DE NOTIFICAÇÕES
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            visible: !root.sensitiveData
            id: notificationList
            model: ListModel {
                id: notificationModel
            }

            delegate: Rectangle {
                width: notificationList.width
                height: Math.max(80, notificationContent.implicitHeight + 20)
                color: Qt.rgba(0.2, 0.2, 0.2, 0.7)
                border.color: borderColorManager.getColorForApp(model.appname)
                border.width: 2
                radius: 8
                clip: true

                MouseArea {
                    id: notificationClickArea
                    anchors.fill: parent
                    anchors.rightMargin: closeButton.width + 10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        console.log("Notification clicked for app:", model.appname)
                        clickRedirectHandler.handleNotificationClick(model.appname, model.id)
                    }

                    onEntered: {
                        parent.color = Qt.rgba(0.25, 0.25, 0.35, 0.8)
                    }

                    onExited: {
                        parent.color = Qt.rgba(0.2, 0.2, 0.2, 0.7)
                    }
                }

                Button {
                    id: closeButton
                    text: "X"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 5
                    width: 24
                    height: 24
                    font.pixelSize: 12
                    onClicked: {
                        closeNotificationProcess.command = ["dunstctl", "close", model.id]
                        closeNotificationProcess.running = true

                        removeNotificationProcess.command = ["dunstctl", "history-rm", model.id]
                        removeNotificationProcess.running = true

                        notificationModel.remove(index)
                    }
                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.pressed ? "#f38ba8" : "#b8c0e0"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    id: notificationContent
                    anchors.left: parent.left
                    anchors.right: closeButton.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 5
                    spacing: 5
                    clip: true

                    // CABEÇALHO (App + Tempo)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Text {
                            id: summaryText
                            text: model.summary || "Sem título"
                            font.pixelSize: Math.max(11, Math.min(13, root.panelWidth * 0.048))
                            font.bold: true
                            color: root.getUrgencyColor(model.urgency)
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            Layout.fillWidth: true

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                visible: summaryText.truncated

                                property var tooltip: styledToolTip.createObject(this, { text: model.summary })

                                onEntered: tooltip.open()
                                onExited: tooltip.close()
                            }
                        }

                        Column {
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                            Layout.preferredWidth: 60
                            spacing: 2

                            Text {
                                text: root.formatTimestamp(model.timestamp)
                                font.pixelSize: Math.max(7, Math.min(9, root.panelWidth * 0.033))
                                color: "#a6adc8"
                                elide: Text.ElideRight
                                width: parent.width
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: model.appname || "App"
                                font.pixelSize: Math.max(7, Math.min(9, root.panelWidth * 0.033))
                                font.bold: true
                                color: "#b8c0e0"
                                elide: Text.ElideRight
                                width: parent.width
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // CORPO DA NOTIFICAÇÃO
                    Text {
                        id: bodyText
                        text: model.body || ""
                        font.pixelSize: Math.max(9, Math.min(11, root.panelWidth * 0.041))
                        color: "#cad3f5"
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 4
                        Layout.fillWidth: true
                        Layout.maximumWidth: parent.width
                        visible: text !== ""

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            visible: bodyText.truncated

                            property var tooltip: styledToolTip.createObject(this, { text: model.body })

                            onEntered: tooltip.open()
                            onExited: tooltip.close()
                        }
                    }
                }
            }
            spacing: 10
        }
    }

    // STATUS
    Text {
        id: statusText
        text: root.sensitiveData ? "Notificações pausadas" : "Carregando..."
        font.pixelSize: Math.max(10, Math.min(12, root.panelWidth * 0.045))
        color: "#aaaaaa"
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
    }

    Process {
        id: closeNotificationProcess
    }

    Process {
        id: removeNotificationProcess
    }

    // PROCESSO PARA BUSCAR NOTIFICAÇÕES
    Process {
        id: notificationProcess
        command: ["dunstctl", "history", "--json"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.sensitiveData) {
                    statusText.text = "Notificações pausadas"
                    notificationModel.clear()
                    notificationTimer.start()
                    return
                }
                try {
                    let jsonData = JSON.parse(this.text)
                    notificationModel.clear()

                    if (jsonData.data && jsonData.data.length > 0) {
                        let notifications = jsonData.data[0];

                        for (let i = 0; i < notifications.length; i++) {
                            let notification = notifications[i];
                            let notificationId = notification.id?.data || 0;
                            let appName = notification.appname?.data || "";

                            if (notificationFilter.shouldDisplayNotification(appName)) {
                                notificationModel.append({
                                    summary: notification.summary?.data || "",
                                    body: notification.body?.data || "",
                                    appname: appName,
                                    urgency: notification.urgency?.data || "",
                                    timestamp: notification.timestamp?.data || 0,
                                    id: notificationId
                                })
                            } else {
                                console.log("Notification from", appName, "filtered out")
                            }
                        }
                        statusText.text = `${notificationModel.count} notificações recentes`
                    } else {
                        statusText.text = "Nenhuma notificação"
                    }
                } catch (e) {
                    statusText.text = "Erro ao ler notificações: " + e.toString()
                    console.log("Erro JSON:", e.toString())
                }

                notificationTimer.start()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    statusText.text = "Erro dunstctl: " + this.text.trim()
                    notificationTimer.start()
                }
            }
        }
    }

    // TIMER PARA ATUALIZAÇÃO AUTOMÁTICA
    Timer {
        id: notificationTimer
        interval: 30000
        onTriggered: {
            if (!root.sensitiveData) {
                notificationProcess.running = true
            }
        }
    }

    // FUNÇÕES AUXILIARES
    function formatTimestamp(timestamp) {
        if (!timestamp || timestamp === 0) return ""

        let date = new Date(timestamp * 1000)
        let now = new Date()
        let diff = now - date

        if (diff < 60000) {
            return "agora"
        } else if (diff < 3600000) {
            return Math.floor(diff / 60000) + "m atrás"
        } else if (diff < 86400000) {
            return Math.floor(diff / 3600000) + "h atrás"
        } else {
            return Qt.formatDateTime(date, "dd/MM HH:mm")
        }
    }

    function getUrgencyColor(urgency) {
        switch(urgency) {
            case "LOW": return "#89b4fa"
            case "NORMAL": return "#a6e3a1"
            case "CRITICAL": return "#f38ba8"
            default: return "#cad3f5"
        }
    }
}
