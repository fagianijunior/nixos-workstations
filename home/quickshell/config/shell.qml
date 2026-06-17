import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." // para carregar Graph.qml e PieChart.qml
import "./filters" // para carregar NotificationFilter.qml
import "./colors" // para carregar BorderColorManager.qml
import "./interaction" // para carregar ClickRedirectHandler.qml
import "./battery" // para carregar BatteryGraph.qml
import "./taskwarrior" // para carregar TaskPanel.qml

PanelWindow {
	id:rootPanel
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
            // You could show a user notification here if desired
        }
    }

    Component.onCompleted: {
        checksensitiveDataProcess.running = true
    }

    Component {
        id: styledToolTip
        ToolTip {
            id: toolTip
            background: Rectangle {
                color: "#24273a" // Base color from Catppuccin Macchiato
                border.color: "#89b4fa" // Blue color
                border.width: 1
                radius: 4
            }
            contentItem: Text {
                text: toolTip.text
                color: "#cad3f5" // Text color
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                padding: 8
            }
        }
    }

    Process {
        id: checksensitiveDataProcess
        command: ["dunstctl", "is-paused"]
        property string statusText: ""
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

    Button {
        id: pauseButton
        text: rootPanel.sensitiveData ? "⊙" : "⊘"
        anchors.right: parent.right
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
            color: parent.pressed ? "#585b70" : "#313244"
            border.color: "#6c7086"
            border.width: 1
            radius: 5
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
            color: "#cad3f5" // Catppuccin Macchiato Text
            horizontalAlignment: Text.AlignHCenter
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
            color: "#cad3f5" // Catppuccin Macchiato Text
            horizontalAlignment: Text.AlignHCenter
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
        ColumnLayout {
            visible: !rootPanel.sensitiveData

            RowLayout {
                Layout.fillWidth: true

                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: "Agenda"
                    font.pixelSize: Math.max(14, Math.min(18, rootPanel.width * 0.07))
                    font.bold: true
                    color: "#cad3f5"
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.Left
                    Layout.fillWidth: true
                }

                Button {
                    id: refreshEventsButton
                    text: "↻"
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
                            font.pixelSize: Math.max(12, Math.min(14, rootPanel.width * 0.052))
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
                    font.pixelSize: Math.max(8, Math.min(18, rootPanel.width * 0.07))
                }
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
         
        // CPU
        Graph {
            id: cpuGraph
            label: "CPU"
            color: "#a6e3a1" // Green
            valueSuffix: "%"
	        maxValue: 100
	        Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }
        Process {
            id: cpuProcess
            command: ["fish", "-c", "grep 'cpu ' /proc/stat; sleep 3; grep 'cpu ' /proc/stat"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = this.text.trim().split("\n")
                    if (lines.length === 2) {
                        let vals1 = lines[0].split(/\s+/).slice(1).map(Number)
                        let vals2 = lines[1].split(/\s+/).slice(1).map(Number)
                        let idle1 = vals1[3], idle2 = vals2[3]
                        let total1 = vals1.reduce((a,b)=>a+b,0)
                        let total2 = vals2.reduce((a,b)=>a+b,0)
                        let totalDiff = total2 - total1
                        let idleDiff = idle2 - idle1
                        let usage = Math.round(100 * (1 - idleDiff / totalDiff))
                        cpuGraph.addValue(usage)
                    }
                    cpuProcess.running = true
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        cpuGraph.label = "CPU (Erro)"
                    }
                }
            }
        }

        // GPU USAGE (VRAM)
        Graph {
            id: gpuUsageGraph
            label: "VRAM"
            color: "#f38ba8" // Red
            valueSuffix: "%"
            maxValue: 100
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }

    	// MEMÓRIA
        Graph {
            id: memGraph
            label: "Memória"
            color: "#89b4fa" // Blue
            valueSuffix: "%"
            maxValue: 100
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }
        
        // SWAP
        Graph {
            id: swapGraph
            label: "SWAP"
            color: "#cba6f7" // Mauve
            valueSuffix: "%"
            maxValue: 100
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }
        
        // PROCESSO UNIFICADO
        Process {
            id: memoryMonitorProcess
            command: ["fish", "-c", "free | grep -E '(Mem.|Swap)'; sleep 3"]
            running: true
            
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = this.text.trim().split('\n')
                    
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i].trim()
                        if (line === "") continue
                        
                        let vals = line.split(/\s+/)
                        if (vals.length < 3) continue
                        
                        let type = vals[0] // "Mem:" ou "Swap:"
                        let total = Number(vals[1])
                        let used = Number(vals[2])
                        
                        // Evita divisão por zero
                        if (total === 0) continue
                        
                        let percent = Math.round((used / total) * 100)
                        
                        // Atualiza o gráfico correspondente
                        if (type === "Mem.:") {
                            memGraph.addValue(percent)
                        } else if (type === "Swap:") {
                            swapGraph.addValue(percent)
                        }
                    }
                    
                    // Reinicia o processo
                    memoryMonitorProcess.running = true
                }
            }
            
            stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        memGraph.label = "Mem (Erro)"
                        swapGraph.label = "Swap (Erro)"
                    }
                }
            }
        }

        // TEMPERATURA
        Graph {
            id: tempGraph
            label: "Temp CPU"
            color: "#fab387" // Peach
            valueSuffix: "°C"
	        maxValue: 100
	        Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }
        Process {
            id: tempProcess
            command: ["fish", "-c", "sensors | grep -E 'Tctl|Package id 0' | awk '{print $2}' | sed 's/+//;s/°C//' | cut -d'.' -f1 | head -n1; sleep 3"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let val = parseFloat(this.text.trim())
                    tempGraph.addValue(val)
                    tempProcess.running = true
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        tempGraph.label = "Temp (Erro)"
                    }
                }
            }
        }

        // GPU TEMPERATURE
        Graph {
            id: gpuTempGraph
            label: "Temp GPU"
            color: "#fab387" // Peach
            valueSuffix: "°C"
            maxValue: 100
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }

        Process {
            id: gpuUsageProcess
            command: ["fish", "-c", "
                set GPU_DEVICE_PATH /sys/class/drm/card1/device

                if test -f \"$GPU_DEVICE_PATH/mem_info_vram_total\" -a -f \"$GPU_DEVICE_PATH/mem_info_vram_used\"
                    set VRAM_TOTAL (cat \"$GPU_DEVICE_PATH/mem_info_vram_total\")
                    set VRAM_USED  (cat \"$GPU_DEVICE_PATH/mem_info_vram_used\")

                    if test $VRAM_TOTAL -gt 0
                        math \"($VRAM_USED * 100) / $VRAM_TOTAL\"
                    else
                        echo 0
                    end
                else
                    echo -1
                end

                sleep 3
            "]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let usage = parseInt(this.text.trim())
                    if (!isNaN(usage) && usage >= 0) {
                        gpuUsageGraph.addValue(usage)
                    } else if (this.text.trim() !== "") {
                         gpuUsageGraph.label = "VRAM (Não encontrado)"
                    }
                    gpuUsageProcess.running = true
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        gpuUsageGraph.label = "VRAM (Erro)"
                    }
                }
            }
        }

        Process {
            id: gpuTempProcess
            command: ["fish", "-c", "
                set HWMON_PATH /sys/class/drm/card1/device/hwmon/hwmon4

                if test -f \"$HWMON_PATH/temp1_input\"
                    set TEMP (cat \"$HWMON_PATH/temp1_input\")
                    math \"$TEMP / 1000\"
                else
                    echo -1
                end

                sleep 3
            "]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let temp = parseInt(this.text.trim())
                    if (!isNaN(temp) && temp >= 0) {
                        gpuTempGraph.addValue(temp)
                    } else if (this.text.trim() !== "") {
                        gpuTempGraph.label = "Temp GPU (Não enc.)"
                    }
                    gpuTempProcess.running = true
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        gpuTempGraph.label = "Temp GPU (Erro)"
                    }
                }
            }
        }

        // BATTERY MONITORING (Device-specific)
        BatteryGraph {
            id: batteryGraph
        }

        // TASKWARRIOR PANEL
        TaskPanel {
            id: taskPanel
            Layout.fillWidth: true
            Layout.preferredHeight: 300  // Reduced from 300 for more compact display
            visible: !rootPanel.sensitiveData  // Respect privacy mode
        }

        // GRÁFICOS DE DISCO (DINÂMICOS)
        RowLayout {
            id: diskChartsLayout
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
        }
        
        Process {
            id: diskMonitorProcess
            command: ["fish", "-c", `echo "oi" | df -h | grep -E '^/dev/' | awk '{print $6 ":" $5}' | sed 's/%//' | sort`]
            running: true
           
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = this.text.trim().split('\n')
                    let colors = ["#cba6f7", "#fab387", "#89b4fa", "#a6e3a1", "#f38ba8"] // Mauve, Peach, Blue, Green, Red
                    let diskData = []
                    
                    for (let i = 0; i < lines.length && i < colors.length; i++) {
                        let line = lines[i].trim()
                        if (line === "") continue
                        
                        let parts = line.split(':')
                        if (parts.length !== 2) continue
                        
                        let mountPoint = parts[0]
                        let usage = parseInt(parts[1])
                        
                        // Adiciona todos os pontos de montagem principais (não apenas os específicos)
                        // Filtra apenas pontos que começam com / e não são temporários
                        if (mountPoint.startsWith("/") && !mountPoint.includes("snap") && 
                            !mountPoint.includes("loop") && mountPoint.length < 20) {
                            diskData.push({
                                mountPoint: mountPoint,
                                usage: usage,
                                color: colors[i % colors.length]
                            })
                        }
                    }
                    
                    // Update the UI immediately
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
                                        
                    // Agenda próxima execução
                    diskTimer.start()
                }
            }    stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        diskChartsLayout.children[0].label = "Disco (Erro)"
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
        // REDE (DOWNLOAD)
        Graph {
            id: netGraph
            label: "DOWN ↓"
            color: "#94e2d5" // Teal
            valueSuffix: " KB/s"
            maxValue: 60000 // escala para até 60 MB/s
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }
        
        // REDE (UPLOAD)
        Graph {
            id: netGraphUpload
            label: "UP ↑"
            color: "#fab387" // Peach
            valueSuffix: " KB/s"
            maxValue: 30000 // escala para até 30 MB/s
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(20, rootPanel.width * 0.2)
        }
        
        // PROCESSO UNIFICADO DE REDE
        Process {
            id: networkMonitorProcess
            running: true
            command: ["fish", "-c", "
                set IFACE (ip route | grep '^default' | awk '{print $5; exit}')
                set RX1 (cat /sys/class/net/$IFACE/statistics/rx_bytes)
                set TX1 (cat /sys/class/net/$IFACE/statistics/tx_bytes)
                sleep 3
                set RX2 (cat /sys/class/net/$IFACE/statistics/rx_bytes)
                set TX2 (cat /sys/class/net/$IFACE/statistics/tx_bytes)
                set DOWN (math \"($RX2 - $RX1) / 3 / 1024\")
                set UP   (math \"($TX2 - $TX1) / 3 / 1024\")
                echo \"DOWN:$DOWN\"
                echo \"UP:$UP\"
            "]
            
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = this.text.trim().split('\n')
                    
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i].trim()
                        if (line === "") continue
                        
                        let parts = line.split(':')
                        if (parts.length !== 2) continue
                        
                        let type = parts[0]
                        let value = parseInt(parts[1])
                        
                        // Atualiza o gráfico correspondente
                        if (type === "DOWN") {
                            netGraph.addValue(value)
                        } else if (type === "UP") {
                            netGraphUpload.addValue(value)
                        }
                    }
                    
                    // Reinicia o processo
                    networkMonitorProcess.running = true
                }
            }
            
            stderr: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "") {
                        netGraph.label = "Down (Erro)"
                        netGraphUpload.label = "Up (Erro)"
                    }
                }
            }
        }

	    // TÍTULO NOTIFICAÇÕES
	    RowLayout {
            visible: !rootPanel.sensitiveData

            spacing: 10
            Layout.fillWidth: true
            Text {
                text: "Notificações"
                font.pixelSize: Math.max(14, Math.min(18, rootPanel.width * 0.07))
                font.bold: true
                color: "#cad3f5" // Catppuccin Macchiato Text
                horizontalAlignment: Text.Left

                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // BOTÕES DE CONTROLE DE NOTIFICAÇÃO
            Button {
                id: refreshButton
                text: "↻"
                onClicked: {
                    notificationProcess.running = true
                }
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : "#313244" // Surface1 : Surface0
                    border.color: "#6c7086" // Surface2
                    radius: 5
                }
                contentItem: Text {
                    text: refreshEventsButton.text
                    color: "#cad3f5"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Process {
            id: dunstPauseToggleProcess
            command: ["dunstctl", "set-paused", "toggle"]
            stdout: StdioCollector {
                onStreamFinished: {
                    // Após o toggle, checa o novo estado para atualizar a UI
                    checksensitiveDataProcess.running = true
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    // Garante a atualização do estado mesmo se o comando der erro
                    checksensitiveDataProcess.running = true
                }
            }
        }

        // LISTA DE NOTIFICAÇÕES
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                visible: !rootPanel.sensitiveData
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
                    clip: true // Importante: evita que o conteúdo ultrapasse os limites

                    // Click handler for notification redirection
                    MouseArea {
                        id: notificationClickArea
                        anchors.fill: parent
                        anchors.rightMargin: closeButton.width + 10 // Don't overlap with close button
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            console.log("Notification clicked for app:", model.appname)
                            clickRedirectHandler.handleNotificationClick(model.appname, model.id)
                        }
                        
                        onEntered: {
                            parent.color = Qt.rgba(0.25, 0.25, 0.35, 0.8) // Slightly lighter on hover
                        }
                        
                        onExited: {
                            parent.color = Qt.rgba(0.2, 0.2, 0.2, 0.7) // Back to original
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
                            color: parent.pressed ? "#f38ba8" : "#b8c0e0" // Red : Subtext1
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
                        clip: true // Garante que o conteúdo não ultrapasse
                        
                        // CABEÇALHO (App + Tempo)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            
                            // TÍTULO DA NOTIFICAÇÃO
                            Text {
                                id: summaryText
                                text: model.summary || "Sem título"
                                font.pixelSize: Math.max(11, Math.min(13, rootPanel.width * 0.048))
                                font.bold: true
                                color: getUrgencyColor(model.urgency)
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
                                    text: formatTimestamp(model.timestamp)
                                    font.pixelSize: Math.max(7, Math.min(9, rootPanel.width * 0.033))
                                    color: "#a6adc8" // Catppuccin Macchiato Subtext0
                                    elide: Text.ElideRight
                                    width: parent.width
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    text: model.appname || "App"
                                    font.pixelSize: Math.max(7, Math.min(9, rootPanel.width * 0.033))
                                    font.bold: true
                                    color: "#b8c0e0" // Catppuccin Macchiato Subtext1
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
                            font.pixelSize: Math.max(9, Math.min(11, rootPanel.width * 0.041))
                            color: "#cad3f5" // Catppuccin Macchiato Text
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
            text: rootPanel.sensitiveData ? "Notificações pausadas" : "Carregando..."
            font.pixelSize: Math.max(10, Math.min(12, rootPanel.width * 0.045))
            color: "#aaaaaa"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
        }
    }

    Process {
        id: closeNotificationProcess
        // O comando será definido no onClicked do botão
    }

    Process {
        id: removeNotificationProcess
        // O comando será definido no onClicked do botão
    }

    // PROCESSO PARA BUSCAR NOTIFICAÇÕES
    Process {
        id: notificationProcess
        command: ["dunstctl", "history", "--json"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (rootPanel.sensitiveData) {
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

                            // Apply notification filter
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
        interval: 30000 // 30 segundos
        onTriggered: {
            if (!rootPanel.sensitiveData) {
                notificationProcess.running = true
            }
        }
    }

    // FUNÇÕES AUXILIARES
    function formatTimestamp(timestamp) {
        if (!timestamp || timestamp === 0) return ""
        
        let date = new Date(timestamp * 1000) // dunstctl timestamp is in seconds
        let now = new Date()
        let diff = now - date
        
        if (diff < 60000) { // menos de 1 min
            return "agora"
        } else if (diff < 3600000) { // menos de 1 hora
            return Math.floor(diff / 60000) + "m atrás"
        } else if (diff < 86400000) { // menos de 1 dia
            return Math.floor(diff / 3600000) + "h atrás"
        } else {
            return Qt.formatDateTime(date, "dd/MM HH:mm")
        }
    }
    
    function getUrgencyColor(urgency) {
        switch(urgency) {
            case "LOW": return "#89b4fa" // Blue
            case "NORMAL": return "#a6e3a1" // Green
            case "CRITICAL": return "#f38ba8" // Red
            default: return "#cad3f5" // Text
        }
    }
}


