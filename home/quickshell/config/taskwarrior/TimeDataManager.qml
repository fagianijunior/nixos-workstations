// TimeDataManager.qml
// Executa timew-summary.py via Process e expõe métricas de tempo para o TaskPanel.
// Atualiza automaticamente a cada 60 segundos.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: timeDataManager

    // ---- Propriedades expostas ----

    // Totais do dia em segundos
    property int todayWorkSeconds:     0
    property int todayPersonalSeconds: 0
    property int todayOtherSeconds:    0

    // Lista de projetos do dia: [{project, seconds, type}]
    property var byProject: []

    // Tarefa ativa: {description, project, elapsed_seconds} ou null
    property var activeTask: null

    // Dados da semana: [{date, label, work_seconds, personal_seconds}] (7 itens)
    property var weekData: []

    // Estado
    property bool   isLoading:    false
    property string errorMessage: ""
    property string lastUpdated:  ""

    // ---- Sinal ----
    signal dataReady()

    // ---- Método público ----
    function refresh() {
        isLoading    = true
        errorMessage = ""
        summaryProcess.running = true
    }

    // ---- Timer de auto-refresh (60 s) ----
    Timer {
        id: autoRefreshTimer
        interval: 60000
        running:  true
        repeat:   true
        onTriggered: timeDataManager.refresh()
    }

    // ---- Process: executa timew-summary.py ----
    Process {
        id: summaryProcess
        command: ["python3", Quickshell.env("HOME") + "/.config/task/timew-summary.py"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                timeDataManager.parseResult(this.text.trim())
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                var msg = this.text.trim()
                if (msg !== "") {
                    timeDataManager.isLoading    = false
                    timeDataManager.errorMessage = "Erro no script: " + msg
                    console.error("TimeDataManager stderr:", msg)
                }
            }
        }
    }

    // ---- Parser do JSON retornado pelo script ----
    function parseResult(text) {
        isLoading = false

        if (!text || text === "") {
            errorMessage = "Script retornou vazio"
            return
        }

        var data
        try {
            data = JSON.parse(text)
        } catch (e) {
            errorMessage = "JSON inválido: " + e.message
            console.error("TimeDataManager parse error:", e.message, "\nText:", text)
            return
        }

        if (data.error) {
            errorMessage = data.error
            console.warn("TimeDataManager script error:", data.error)
            // Continua com zeros caso o script tenha retornado estrutura vazia
        } else {
            errorMessage = ""
        }

        var t = data.today || {}
        todayWorkSeconds     = t.work_seconds     || 0
        todayPersonalSeconds = t.personal_seconds || 0
        todayOtherSeconds    = t.other_seconds    || 0
        byProject            = t.by_project       || []
        activeTask           = t.active_task      || null

        weekData = data.week || []

        // Timestamp da última atualização
        var now = new Date()
        lastUpdated = Qt.formatTime(now, "HH:mm:ss")

        dataReady()
    }

    // ---- Carga inicial ----
    Component.onCompleted: {
        refresh()
    }
}
