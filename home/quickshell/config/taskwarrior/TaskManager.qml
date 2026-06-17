// TaskManager.qml - Data Layer Component
// Handles Taskwarrior command execution, JSON parsing, and data management
// Validates: Requirements 6.1, 8.1, 8.3

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: taskManager
    
    // ---- Exposed Data Properties ----
    
    // Map of client names to task arrays: { "client-name": [tasks], ... }
    property var tasksByClient: ({})
    
    // Array of tasks without a client attribute
    property var generalTasks: []
    
    // Loading state indicator
    property bool isLoading: false
    
    // Error message from last operation (empty string if no error)
    property string errorMessage: ""
    
    // ---- Configuration Properties ----
    
    // Refresh interval in milliseconds (default: 7 seconds)
    property int refreshInterval: 7000
    
    // Whether to use file watcher (vs polling only)
    property bool useFileWatcher: true
    
    // ---- Signals ----
    
    // Emitted when task data has been refreshed
    signal tasksUpdated()
    
    // Emitted when a task modification completes
    // @param uuid: Task UUID that was modified
    // @param success: Whether the modification succeeded
    signal taskModified(string uuid, bool success)
    
    // Emitted when an error occurs
    // @param message: Error description
    signal errorOccurred(string message)
    
    // Emitted when a start/stop/modify-time operation completes
    signal timerOperationCompleted(string uuid, bool success, string operation)
    
    // Emitted when a timer error occurs with a display message
    signal timerError(string message)
    
    // ---- Process Components ----
    
    // Process for executing `task export` command
    Process {
        id: taskExportProcess
        // Include pending, waiting, and completed tasks (filter by date happens in groupTasksByClient)
        // Using OR syntax: ( status:pending or status:waiting or status:completed )
        command: ["task", "(", "status:pending", "or", "status:waiting", "or", "status:completed", ")", "export"]
        running: false
        
        stdout: StdioCollector {
            id: taskExportStdout
            
            onStreamFinished: {
                taskManager.parseAndGroupTasks(this.text)
            }
        }
        
        stderr: StdioCollector {
            id: taskExportStderr
            
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    taskManager.errorMessage = "Error loading tasks: " + this.text.trim()
                    taskManager.errorOccurred(taskManager.errorMessage)
                    console.error("Taskwarrior error:", this.text)
                    taskManager.isLoading = false
                }
            }
        }
    }
    
    // Process for executing task modification commands
    // Validates: Requirements 4.3, 4.4, 10.1
    Process {
        id: taskModifyProcess
        command: []
        running: false
        
        property string modifyingUuid: ""
        
        stdout: StdioCollector {
            id: taskModifyStdout
            
            onStreamFinished: {
                // Task modification succeeded
                console.log("Task modified successfully:", taskModifyProcess.modifyingUuid)
                taskManager.taskModified(taskModifyProcess.modifyingUuid, true)
                // Refresh tasks to reflect the change
                taskManager.refreshTasks()
            }
        }
        
        stderr: StdioCollector {
            id: taskModifyStderr
            
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    // Task modification failed
                    taskManager.errorMessage = "Failed to modify task: " + this.text.trim()
                    taskManager.errorOccurred(taskManager.errorMessage)
                    console.error("Task modification error:", this.text)
                    taskManager.taskModified(taskModifyProcess.modifyingUuid, false)
                }
            }
        }
    }
    
    // ---- Timer Process for start/stop/modify-time commands ----
    // Validates: Requirements 1.5, 2.4, 2.5, 5.1
    
    Process {
        id: timerProcess
        command: []
        running: false
        
        property string operatingUuid: ""
        property string operation: "" // "start", "stop", "modify-time", "auto-stop", "auto-modify-time"
        property int pendingElapsedSeconds: 0
        property string pendingStartUuid: "" // UUID to start after auto-stop completes
        
        stdout: StdioCollector {
            id: timerStdout
            onStreamFinished: {
                if (timerProcess.operation === "stop") {
                    // Stop succeeded — now persist accumulated time
                    timerProcess.operation = "modify-time"
                    timerProcess.command = ["task", "rc.confirmation:off",
                        timerProcess.operatingUuid, "modify",
                        "totalactivetime:" + timerProcess.pendingElapsedSeconds]
                    timerProcess.running = true
                } else if (timerProcess.operation === "modify-time") {
                    // Full pause sequence complete
                    taskManager.timerOperationCompleted(timerProcess.operatingUuid, true, "pause")
                    taskManager.refreshTasks()
                } else if (timerProcess.operation === "start") {
                    taskManager.timerOperationCompleted(timerProcess.operatingUuid, true, "start")
                    taskManager.refreshTasks()
                } else if (timerProcess.operation === "auto-stop") {
                    // Auto-stop succeeded — now persist accumulated time for the stopped task
                    timerProcess.operation = "auto-modify-time"
                    timerProcess.command = ["task", "rc.confirmation:off",
                        timerProcess.operatingUuid, "modify",
                        "totalactivetime:" + timerProcess.pendingElapsedSeconds]
                    timerProcess.running = true
                } else if (timerProcess.operation === "auto-modify-time") {
                    // Auto-stop modify complete — now start the new task
                    timerProcess.operatingUuid = timerProcess.pendingStartUuid
                    timerProcess.operation = "start"
                    timerProcess.pendingStartUuid = ""
                    timerProcess.command = ["task", "rc.confirmation:off", timerProcess.operatingUuid, "start"]
                    timerProcess.running = true
                }
            }
        }
        
        stderr: StdioCollector {
            id: timerStderr
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    if (timerProcess.operation === "modify-time") {
                        // Stop succeeded but modify failed
                        var msg = "Time not saved for task. Unsaved value: " +
                            timerProcess.pendingElapsedSeconds + "s"
                        taskManager.timerError(msg)
                        console.error("Timer: Failed to persist totalactivetime=" +
                            timerProcess.pendingElapsedSeconds +
                            " for task " + timerProcess.operatingUuid)
                        taskManager.timerOperationCompleted(timerProcess.operatingUuid, false, "modify-time")
                    } else if (timerProcess.operation === "auto-stop") {
                        // Auto-stop failed — do not start the new task
                        taskManager.timerError("Could not stop active task: " + this.text.trim())
                        taskManager.timerOperationCompleted(timerProcess.operatingUuid, false, "auto-stop")
                        timerProcess.pendingStartUuid = ""
                    } else if (timerProcess.operation === "auto-modify-time") {
                        // Auto-stop modify failed — log error but still start the new task
                        var autoMsg = "Time not saved for stopped task. Unsaved value: " +
                            timerProcess.pendingElapsedSeconds + "s"
                        taskManager.timerError(autoMsg)
                        console.error("Timer: Failed to persist totalactivetime=" +
                            timerProcess.pendingElapsedSeconds +
                            " for task " + timerProcess.operatingUuid)
                        // Still proceed to start the new task
                        timerProcess.operatingUuid = timerProcess.pendingStartUuid
                        timerProcess.operation = "start"
                        timerProcess.pendingStartUuid = ""
                        timerProcess.command = ["task", "rc.confirmation:off", timerProcess.operatingUuid, "start"]
                        timerProcess.running = true
                    } else {
                        taskManager.timerError("Timer command failed: " + this.text.trim())
                        taskManager.timerOperationCompleted(timerProcess.operatingUuid, false, timerProcess.operation)
                    }
                    taskManager.refreshTasks()
                }
            }
        }
    }
    
    // ---- Timer Error Display ----
    
    Timer {
        id: timerErrorClearTimer
        interval: 5000
        running: false
        onTriggered: taskManager.errorMessage = ""
    }
    
    // Wire timerError signal to set errorMessage and restart the clear timer
    onTimerError: function(message) {
        taskManager.errorMessage = message
        timerErrorClearTimer.restart()
    }
    
    // ---- Public Methods ----
    
    // Load tasks from Taskwarrior via `task export`
    function refreshTasks() {
        isLoading = true
        errorMessage = ""
        taskExportProcess.running = true
    }
    
    // Update a task's status
    // @param uuid: Task UUID to modify
    // @param newStatus: New status value (e.g., "completed", "pending")
    // Validates: Requirements 4.3, 4.4, 10.1
    function updateTaskStatus(uuid, newStatus) {
        if (!uuid || uuid.trim() === "") {
            console.error("updateTaskStatus: Invalid UUID provided")
            taskManager.errorOccurred("Invalid task UUID")
            taskManager.taskModified("", false)
            return
        }
        
        // Store the UUID being modified
        taskModifyProcess.modifyingUuid = uuid
        
        // Build command based on the new status
        let cmd = []
        if (newStatus === "completed" || newStatus === "done") {
            // Use the shorthand "done" command
            cmd = ["task", uuid, "done"]
        } else if (newStatus === "pending") {
            // Use modify command to set status back to pending
            cmd = ["task", uuid, "modify", "status:pending"]
        } else {
            // Generic status modification
            cmd = ["task", uuid, "modify", "status:" + newStatus]
        }
        
        console.log("Executing task modification:", cmd.join(" "))
        
        // Set command and start process (non-blocking)
        taskModifyProcess.command = cmd
        taskModifyProcess.running = true
    }
    
    // Get the number of tasks for a specific client
    // @param clientName: Name of the client
    // @return: Number of tasks for that client
    function getTaskCount(clientName) {
        if (tasksByClient[clientName]) {
            return tasksByClient[clientName].length
        }
        return 0
    }
    
    // ---- Timer Public Methods ----
    // Validates: Requirements 1.1, 1.3, 1.4, 2.1, 2.2, 3.1, 4.1, 4.2
    
    // Start a task (with auto-stop of any currently active task)
    function startTask(uuid) {
        // Find currently active task (if any)
        var activeUuid = findActiveTaskUuid()
        
        if (activeUuid && activeUuid !== uuid) {
            // Must stop active task first — compute its elapsed time
            var activeTask = findTaskByUuid(activeUuid)
            if (activeTask) {
                var elapsed = computeElapsedForTask(activeTask)
                // Chain: stop active → modify time → start new
                timerProcess.operatingUuid = activeUuid
                timerProcess.operation = "auto-stop"
                timerProcess.pendingElapsedSeconds = elapsed
                timerProcess.pendingStartUuid = uuid
                timerProcess.command = ["task", "rc.confirmation:off", activeUuid, "stop"]
                timerProcess.running = true
                return
            }
        }
        
        // No active task or same task — start directly
        timerProcess.operatingUuid = uuid
        timerProcess.operation = "start"
        timerProcess.pendingStartUuid = ""
        timerProcess.command = ["task", "rc.confirmation:off", uuid, "start"]
        timerProcess.running = true
    }
    
    // Pause (stop) an active task and persist accumulated time
    function pauseTask(uuid, elapsedSeconds) {
        timerProcess.operatingUuid = uuid
        timerProcess.operation = "stop"
        timerProcess.pendingElapsedSeconds = elapsedSeconds
        timerProcess.pendingStartUuid = ""
        timerProcess.command = ["task", "rc.confirmation:off", uuid, "stop"]
        timerProcess.running = true
    }
    
    // ---- Timer Helper Functions ----
    
    // Find the UUID of the currently active task (one with start attribute)
    function findActiveTaskUuid() {
        // Search through client-grouped tasks
        for (var client in tasksByClient) {
            for (var i = 0; i < tasksByClient[client].length; i++) {
                var t = tasksByClient[client][i]
                if (t.start !== undefined && t.start !== "") return t.uuid
            }
        }
        // Search through general tasks
        for (var j = 0; j < generalTasks.length; j++) {
            var g = generalTasks[j]
            if (g.start !== undefined && g.start !== "") return g.uuid
        }
        return ""
    }
    
    // Find a task object by UUID
    function findTaskByUuid(uuid) {
        for (var client in tasksByClient) {
            for (var i = 0; i < tasksByClient[client].length; i++) {
                if (tasksByClient[client][i].uuid === uuid) return tasksByClient[client][i]
            }
        }
        for (var j = 0; j < generalTasks.length; j++) {
            if (generalTasks[j].uuid === uuid) return generalTasks[j]
        }
        return null
    }
    
    // Compute elapsed seconds for a given task object
    function computeElapsedForTask(task) {
        var accumulated = 0
        if (task.totalactivetime) {
            accumulated = parseInt(task.totalactivetime)
            if (isNaN(accumulated)) accumulated = 0
        }
        if (task.start && task.start !== "") {
            var startMs = parseTaskwarriorTimestamp(task.start)
            if (startMs > 0) {
                var sessionSeconds = Math.floor((Date.now() - startMs) / 1000)
                if (sessionSeconds < 0) sessionSeconds = 0
                return accumulated + sessionSeconds
            }
        }
        return accumulated
    }
    
    // Parse Taskwarrior timestamp "YYYYMMDDTHHmmSSZ" to epoch milliseconds
    function parseTaskwarriorTimestamp(ts) {
        if (!ts || ts.length < 15) return 0
        var year   = parseInt(ts.substring(0, 4))
        var month  = parseInt(ts.substring(4, 6)) - 1
        var day    = parseInt(ts.substring(6, 8))
        var hour   = parseInt(ts.substring(9, 11))
        var minute = parseInt(ts.substring(11, 13))
        var second = parseInt(ts.substring(13, 15))
        if (isNaN(year) || isNaN(month) || isNaN(day) ||
            isNaN(hour) || isNaN(minute) || isNaN(second)) return 0
        return Date.UTC(year, month, day, hour, minute, second)
    }
    
    // ---- Internal Methods ----
    
    // Parse JSON from task export and group by client
    function parseAndGroupTasks(jsonText) {
        try {
            // Parse JSON output from Taskwarrior
            const tasks = JSON.parse(jsonText)
            
            // Validate that we got an array
            if (!Array.isArray(tasks)) {
                throw new Error("Expected array from task export, got: " + typeof tasks)
            }
            
            // Use groupTasksByClient to organize tasks
            const result = groupTasksByClient(tasks)
            
            // Update properties
            taskManager.tasksByClient = result.grouped
            taskManager.generalTasks = result.general
            taskManager.isLoading = false
            
            // Emit signal to notify UI
            taskManager.tasksUpdated()
            
            console.log("Tasks loaded successfully:", Object.keys(result.grouped).length, "clients,", result.general.length, "general tasks")
            
        } catch (e) {
            // JSON parsing or processing error
            taskManager.errorMessage = "Error parsing task data: " + e.message
            taskManager.errorOccurred(taskManager.errorMessage)
            taskManager.isLoading = false
            console.error("JSON parse error:", e)
        }
    }
    
    // Group tasks by client attribute
    // Filters to include pending, waiting, and recently completed tasks
    // @param tasks: Array of task objects from Taskwarrior export
    // @return: Object with { grouped: {client: [tasks]}, general: [tasks] }
    // Validates: Requirements 1.1, 1.3
    function groupTasksByClient(tasks) {
        const grouped = {}
        const general = []
        
        // Calculate 24 hours ago timestamp
        const now = new Date()
        const twentyFourHoursAgo = new Date(now.getTime() - (24 * 60 * 60 * 1000))
        
        for (const task of tasks) {
            // Filter logic:
            // - Include: pending, waiting
            // - Include: completed (if within last 24 hours)
            // - Exclude: deleted, old completed tasks
            
            if (task.status === "deleted") {
                continue  // Skip deleted tasks
            }
            
            if (task.status === "completed") {
                // Only include if completed within last 24 hours
                if (task.end) {
                    // Parse Taskwarrior timestamp (format: 20240120T120000Z)
                    const year = parseInt(task.end.substring(0, 4))
                    const month = parseInt(task.end.substring(4, 6)) - 1
                    const day = parseInt(task.end.substring(6, 8))
                    const hour = parseInt(task.end.substring(9, 11))
                    const minute = parseInt(task.end.substring(11, 13))
                    const second = parseInt(task.end.substring(13, 15))
                    
                    const completedDate = new Date(year, month, day, hour, minute, second)
                    
                    if (completedDate < twentyFourHoursAgo) {
                        continue  // Skip old completed tasks
                    }
                } else {
                    continue  // No end date, skip
                }
            }
            
            // Include pending and waiting tasks, and recent completed tasks
            if (task.status === "pending" || task.status === "waiting" || task.status === "completed") {
                const client = task.client
                if (client && client.trim() !== "") {
                    // Task has a client attribute
                    if (!grouped[client]) {
                        grouped[client] = []
                    }
                    grouped[client].push(task)
                } else {
                    // Task has no client attribute - goes to general
                    general.push(task)
                }
            }
        }
        
        return { grouped, general }
    }
}
