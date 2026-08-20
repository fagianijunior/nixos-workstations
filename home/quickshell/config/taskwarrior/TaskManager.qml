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
            // Must stop active task first, then start new one
            var stopAndStartProcess = Qt.createQmlObject(`
                import Quickshell.Io
                Process {
                    property string nextUuid: ""
                    command: []
                    running: false
                    stdout: StdioCollector {
                        onStreamFinished: {
                            // Stop succeeded — start the new task
                            startProcess.command = ["task", "rc.confirmation:off", parent.nextUuid, "start"]
                            startProcess.running = true
                        }
                    }
                    stderr: StdioCollector {
                        onStreamFinished: {
                            if (this.text.trim() !== "") {
                                console.error("Auto-stop failed:", this.text.trim())
                            }
                            // Attempt to start new task anyway
                            startProcess.command = ["task", "rc.confirmation:off", parent.nextUuid, "start"]
                            startProcess.running = true
                        }
                    }
                }
            `, taskManager)
            stopAndStartProcess.nextUuid = uuid
            stopAndStartProcess.command = ["task", "rc.confirmation:off", activeUuid, "stop"]
            stopAndStartProcess.running = true
            return
        }
        
        // No active task or same task — start directly
        startProcess.operatingUuid = uuid
        startProcess.command = ["task", "rc.confirmation:off", uuid, "start"]
        startProcess.running = true
    }
    
    // Process for start operations
    Process {
        id: startProcess
        command: []
        running: false
        property string operatingUuid: ""
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Task started:", startProcess.operatingUuid)
                taskManager.taskModified(startProcess.operatingUuid, true)
                taskManager.refreshTasks()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    taskManager.errorMessage = "Failed to start task: " + this.text.trim()
                    taskManager.errorOccurred(taskManager.errorMessage)
                    taskManager.taskModified(startProcess.operatingUuid, false)
                }
            }
        }
    }

    // Stop an active task (Timewarrior hook handles time tracking)
    function stopTask(uuid) {
        stopProcess.operatingUuid = uuid
        stopProcess.command = ["task", "rc.confirmation:off", uuid, "stop"]
        stopProcess.running = true
    }

    // Process for stop operations
    Process {
        id: stopProcess
        command: []
        running: false
        property string operatingUuid: ""

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Task stopped:", stopProcess.operatingUuid)
                taskManager.taskModified(stopProcess.operatingUuid, true)
                taskManager.refreshTasks()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    taskManager.errorMessage = "Failed to stop task: " + this.text.trim()
                    taskManager.errorOccurred(taskManager.errorMessage)
                    taskManager.taskModified(stopProcess.operatingUuid, false)
                }
            }
        }
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
