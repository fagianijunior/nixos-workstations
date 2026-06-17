// TaskItem.qml - Individual Task Display Component
// Displays a single task with status button, description, and metadata
// Validates: Requirements 4.1, 4.2, 5.1, 5.2, 5.3, 5.4, 8.2, 9.1, 9.2, 9.3, 9.4, 10.2

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: taskItem
    
    // ---- Properties ----
    
    // Task object from Taskwarrior JSON
    property var task: null
    
    // Reference to TaskManager for status updates
    property var taskManager: null
    
    // Internal state for optimistic UI updates
    property string currentStatus: task ? (task.status || "pending") : "pending"
    property string previousStatus: currentStatus
    
    // Detected terminal emulator
    property string detectedTerminal: ""
    property var terminalFallbacks: ["kitty", "alacritty", "wezterm", "foot"]
    property int currentFallbackIndex: 0
    
    // Compositor detection
    property bool isHyprland: false
    
    // ---- Timer Properties ----
    
    // Accumulated seconds from previous work sessions (stored in UDA)
    property int accumulatedSeconds: {
        if (!task || !task.totalactivetime) return 0
        var val = parseInt(task.totalactivetime)
        return isNaN(val) ? 0 : val
    }
    
    // Total elapsed seconds (accumulated + current session), updated by timer tick
    // Not a binding — managed imperatively by timer tick, pause logic, and onTaskChanged
    property int elapsedSeconds: 0
    
    // Whether the timer is actively running (task is active)
    property bool timerRunning: isTaskActive(task)
    
    // Disables pause button during command execution
    property bool pauseInProgress: false
    
    // ---- Visual Properties ----
    
    color: getTaskBackgroundColor(task)  // Dynamic color based on status
    radius: 4
    border.color: isTaskActive(task) ? "#89b4fa" : "#45475a"  // Blue border for active tasks
    border.width: isTaskActive(task) ? 2 : 1
    
    implicitHeight: 40  // Reduced from 60
    
    // ---- Helper Functions ----
    
    // Get icon for task status
    function getStatusIcon(status) {
        switch (status) {
            case "completed":
            case "done":
                return "✓"
            case "pending":
                return "⧖"
            case "waiting":
                return "⏸"
            case "deleted":
                return "✗"
            default:
                return "○"
        }
    }
    
    // Get next status in the cycle
    function getNextStatus(currentStatus) {
        switch (currentStatus) {
            case "waiting":
                return "pending"  // waiting → pending
            case "pending":
                return "completed"  // pending → completed
            case "completed":
                return "pending"  // completed → pending (undo)
            default:
                return "completed"
        }
    }
    
    // Check if task is active (being worked on)
    function isTaskActive(task) {
        return task && task.start !== undefined && task.start !== ""
    }
    
    // Get background color based on task status
    function getTaskBackgroundColor(task) {
        if (!task) return Qt.rgba(0.2, 0.2, 0.2, 0.5)
        
        if (task.status === "completed") {
            return Qt.rgba(0.4, 0.7, 0.4, 0.3)  // Green tint for completed
        } else if (isTaskActive(task)) {
            return Qt.rgba(0.5, 0.6, 0.9, 0.3)  // Blue tint for active
        } else if (task.status === "waiting") {
            return Qt.rgba(0.6, 0.6, 0.2, 0.3)  // Yellow tint for waiting
        }
        
        return Qt.rgba(0.2, 0.2, 0.2, 0.5)  // Default
    }
    
    // Get color for priority level
    function getPriorityColor(priority) {
        switch (priority) {
            case "H":
                return "#f38ba8"  // Red
            case "M":
                return "#fab387"  // Peach
            case "L":
                return "#89b4fa"  // Blue
            default:
                return "#6c7086"  // Gray
        }
    }
    
    // Format due date for display
    function formatDueDate(dueStr) {
        if (!dueStr) return ""
        
        // Parse ISO 8601 timestamp (e.g., "20240120T000000Z")
        const year = parseInt(dueStr.substring(0, 4))
        const month = parseInt(dueStr.substring(4, 6))
        const day = parseInt(dueStr.substring(6, 8))
        
        const dueDate = new Date(year, month - 1, day)
        const now = new Date()
        
        // Calculate days difference
        const diffTime = dueDate - now
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
        
        if (diffDays < 0) {
            return "Overdue " + Math.abs(diffDays) + "d"
        } else if (diffDays === 0) {
            return "Due today"
        } else if (diffDays === 1) {
            return "Due tomorrow"
        } else if (diffDays <= 7) {
            return "Due in " + diffDays + "d"
        } else {
            // Format as MM/DD
            return (month < 10 ? "0" : "") + month + "/" + (day < 10 ? "0" : "") + day
        }
    }
    
    // Check if task is overdue
    function isOverdue(dueStr) {
        if (!dueStr) return false
        
        const year = parseInt(dueStr.substring(0, 4))
        const month = parseInt(dueStr.substring(4, 6))
        const day = parseInt(dueStr.substring(6, 8))
        
        const dueDate = new Date(year, month - 1, day)
        const now = new Date()
        now.setHours(0, 0, 0, 0)  // Reset to start of day
        
        return dueDate < now
    }
    
    // Detect if the compositor is Hyprland
    // Validates: Requirements 5.4
    function detectHyprland() {
        // Check for Hyprland-specific environment variables
        const hyprlandInstance = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
        const xdgCurrentDesktop = Quickshell.env("XDG_CURRENT_DESKTOP")
        
        // Hyprland sets HYPRLAND_INSTANCE_SIGNATURE when running
        if (hyprlandInstance && hyprlandInstance.trim() !== "") {
            console.log("Detected Hyprland compositor via HYPRLAND_INSTANCE_SIGNATURE")
            isHyprland = true
            return
        }
        
        // Fallback: check XDG_CURRENT_DESKTOP
        if (xdgCurrentDesktop && xdgCurrentDesktop.toLowerCase().includes("hyprland")) {
            console.log("Detected Hyprland compositor via XDG_CURRENT_DESKTOP")
            isHyprland = true
            return
        }
        
        console.log("Hyprland compositor not detected")
        isHyprland = false
    }
    
    // Get terminal command with appropriate flags
    function getTerminalCommand(uuid) {
        // Use wezterm with floating window support for Hyprland
        if (isHyprland) {
            return ["wezterm", "start", "--class", "floating", "--", "task", uuid, "edit"]
        }
        
        // Generic wezterm command
        return ["wezterm", "start", "--", "task", uuid, "edit"]
    }
    
    // Open task in terminal for editing
    function openTaskInTerminal(uuid) {
        if (!uuid) {
            console.error("Cannot open task: no UUID provided")
            return
        }
        
        console.log("Opening task in wezterm:", uuid)
        
        terminalProcess.taskUuid = uuid
        terminalProcess.command = getTerminalCommand(uuid)
        terminalProcess.running = true
    }
    
    // ---- Process Components ----
    
    // Non-blocking terminal launch for task detail navigation
    // Validates: Requirements 5.1, 5.2, 5.3, 5.4, 10.2
    Process {
        id: terminalProcess
        
        property string taskUuid: ""
        
        // Command will be set dynamically based on Hyprland detection
        command: ["wezterm", "start", "--", "task", taskUuid, "edit"]
        running: false
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.warn("Terminal launch error:", this.text)
                }
            }
        }
    }
    
    // ---- Timer Component ----
    
    // 1-second tick timer that updates elapsed display while task is active
    Timer {
        id: elapsedTimer
        interval: 1000
        running: taskItem.timerRunning && !taskItem.pauseInProgress
        repeat: true
        onTriggered: taskItem.updateElapsed()
    }
    
    // Update elapsedSeconds property (called every tick)
    function updateElapsed() {
        elapsedSeconds = accumulatedSeconds + currentSessionSeconds()
    }
    
    // Parse Taskwarrior timestamp "YYYYMMDDTHHmmSSZ" → epoch milliseconds
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

    // Calculate current session seconds from start timestamp
    function currentSessionSeconds() {
        if (!task || !task.start || task.start === "") return 0
        var startMs = parseTaskwarriorTimestamp(task.start)
        if (startMs <= 0) return 0
        var session = Math.floor((Date.now() - startMs) / 1000)
        return session < 0 ? 0 : session
    }

    // Format seconds as HH:MM:SS with zero-padding
    function formatTime(totalSeconds) {
        if (totalSeconds < 0) totalSeconds = 0
        var hours   = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var seconds = totalSeconds % 60

        var hh = hours.toString()
        if (hh.length < 2) hh = "0" + hh
        var mm = minutes.toString()
        if (mm.length < 2) mm = "0" + mm
        var ss = seconds.toString()
        if (ss.length < 2) ss = "0" + ss

        return hh + ":" + mm + ":" + ss
    }

    // Get the timer button state: "start", "pause", "resume", or "hidden"
    function timerButtonState() {
        if (!task) return "hidden"
        if (task.status === "completed" || task.status === "deleted") return "hidden"
        if (isTaskActive(task)) return "pause"
        if (accumulatedSeconds > 0) return "resume"
        return "start"
    }
    
    // ---- Layout ----
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 4  // Reduced from 8
        spacing: 6  // Reduced from 8
        
        // Status change button
        // Validates: Requirements 4.1, 4.2
        Rectangle {
            id: statusButton
            Layout.preferredWidth: 20  // Reduced from 32
            Layout.preferredHeight: 20  // Reduced from 32
            radius: 12  // Reduced from 16
            color: statusButtonMouseArea.containsMouse ? "#45475a" : "#24273a"
            border.color: "#89b4fa"
            border.width: 1
            
            Text {
                anchors.centerIn: parent
                text: taskItem.getStatusIcon(taskItem.currentStatus)
                color: "#cad3f5"
                font.pixelSize: 12  // Reduced from 16
            }
            
            MouseArea {
                id: statusButtonMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    console.log("Status button clicked - current status:", taskItem.currentStatus)
                    
                    if (!taskItem.task || !taskItem.task.uuid) {
                        console.error("Cannot update status: no task UUID")
                        return
                    }
                    
                    // Optimistic UI update
                    taskItem.previousStatus = taskItem.currentStatus
                    
                    // Get next status in the cycle: waiting → pending → completed
                    const newStatus = taskItem.getNextStatus(taskItem.currentStatus)
                    taskItem.currentStatus = newStatus
                    
                    console.log("Changing status from", taskItem.previousStatus, "to", newStatus)
                    
                    // Call TaskManager to update status
                    if (taskItem.taskManager) {
                        taskItem.taskManager.updateTaskStatus(taskItem.task.uuid, newStatus)
                    } else {
                        console.error("TaskManager not available")
                    }
                }
            }
        }
        
        // Task description and metadata area
        // Validates: Requirements 9.1, 9.2, 9.3, 9.4
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2  // Reduced from 4
            
            // Task description
            Text {
                id: descriptionText
                text: taskItem.task ? (taskItem.task.description || "Task") : "Task"
                color: "#cad3f5"
                font.pixelSize: 11  // Reduced from 13
                font.bold: taskItem.task && taskItem.task.priority === "H"
                Layout.fillWidth: true
                Layout.fillHeight: true
                elide: Text.ElideRight
                maximumLineCount: 3
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter                
                
                // MouseArea for terminal launch and tooltip
                MouseArea {
                    id: descriptionMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onEntered: {
                        if (taskItem.task && taskItem.task.description) {
                            tooltipTimer.start()
                        }
                    }
                    
                    onExited: {
                        tooltipTimer.stop()
                        if (tooltipPopup.visible) {
                            tooltipPopup.close()
                        }
                    }
                    
                    onClicked: {
                        if (taskItem.task && taskItem.task.uuid) {
                            taskItem.openTaskInTerminal(taskItem.task.uuid)
                        }
                    }
                    
                    Timer {
                        id: tooltipTimer
                        interval: 500
                        onTriggered: {
                            if (descriptionMouseArea.containsMouse && taskItem.task && taskItem.task.description) {
                                tooltipPopup.open()
                            }
                        }
                    }
                }
            }
            
            // Tooltip popup
            Popup {
                id: tooltipPopup
                x: descriptionText.x
                y: descriptionText.y + descriptionText.height + 4
                width: Math.min(400, taskItem.width * 0.8)
                padding: 8
                closePolicy: Popup.NoAutoClose
                
                background: Rectangle {
                    color: "#24273a"
                    border.color: "#89b4fa"
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Column {
                    spacing: 4
                    width: parent.width
                    
                    Text {
                        text: "ID: " + (taskItem.task && taskItem.task.id ? taskItem.task.id : "N/A")
                        color: "#89b4fa"
                        font.pixelSize: 10
                        font.bold: true
                        width: parent.width
                    }
                    
                    Text {
                        text: taskItem.task ? (taskItem.task.description || "") : ""
                        color: "#cad3f5"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
            
            // Metadata row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6  // Reduced from 8
                
                // Tags display
                Repeater {
                    model: taskItem.task && taskItem.task.tags ? taskItem.task.tags : []
                    
                    Text {
                        text: "#" + modelData
                        color: "#89b4fa"
                        font.pixelSize: 8  // Reduced from 9
                    }
                }
                
                // Due date display
                Text {
                    visible: taskItem.task && taskItem.task.due !== undefined && taskItem.task.due !== ""
                    text: taskItem.task ? taskItem.formatDueDate(taskItem.task.due) : ""
                    color: taskItem.task && taskItem.isOverdue(taskItem.task.due) ? "#f38ba8" : "#a6adc8"
                    font.pixelSize: 8  // Reduced from 9
                }
                
                // Timer control button (▶ start/resume or ⏸ pause)
                // Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
                Rectangle {
                    id: timerButton
                    visible: taskItem.timerButtonState() !== "hidden"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: timerButtonMouseArea.containsMouse ? "#45475a" : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: taskItem.timerButtonState() === "pause" ? "⏸" : "▶"
                        color: "#a6e3a1"
                        font.pixelSize: 10
                    }
                    
                    MouseArea {
                        id: timerButtonMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !taskItem.pauseInProgress
                        
                        onClicked: {
                            var state = taskItem.timerButtonState()
                            if (state === "start" || state === "resume") {
                                taskItem.taskManager.startTask(taskItem.task.uuid)
                            } else if (state === "pause") {
                                taskItem.pauseInProgress = true
                                taskItem.updateElapsed()
                                taskItem.taskManager.pauseTask(taskItem.task.uuid, taskItem.elapsedSeconds)
                            }
                        }
                    }
                }
                
                // Timer display text (HH:MM:SS)
                // Validates: Requirements 8.1, 8.2, 8.3, 8.4
                Text {
                    id: timerDisplay
                    visible: taskItem.timerRunning || taskItem.accumulatedSeconds > 0
                    text: taskItem.formatTime(taskItem.elapsedSeconds)
                    color: "#a6e3a1"
                    font.pixelSize: 9
                    font.family: "monospace"
                }
                
                // Spacer
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
    
    // ---- Signal Handlers ----
    
    // Initialize Hyprland detection and elapsed time on component load
    Component.onCompleted: {
        detectHyprland()
        updateElapsed()
    }
    
    // When task data refreshes, recalculate elapsed (unless pause is in progress)
    onTaskChanged: {
        if (!pauseInProgress) {
            updateElapsed()
        }
    }
    
    // Listen for task modification results to revert optimistic updates if needed
    Connections {
        target: taskItem.taskManager
        
        function onTaskModified(uuid, success) {
            if (taskItem.task && taskItem.task.uuid === uuid && !success) {
                // Revert optimistic UI update on failure
                console.warn("Task modification failed, reverting UI state")
                taskItem.currentStatus = taskItem.previousStatus
            }
        }
    }
    
    // Listen for timer operation results to reset pause state
    // Validates: Requirements 9.1, 9.2, 9.3, 9.4
    Connections {
        target: taskItem.taskManager
        
        function onTimerOperationCompleted(uuid, success, operation) {
            if (taskItem.task && taskItem.task.uuid === uuid) {
                taskItem.pauseInProgress = false
                // After pause completes, recalculate from current task data
                taskItem.updateElapsed()
            }
        }
        
        function onTimerError(message) {
            taskItem.pauseInProgress = false
            // Re-enable timer calculation
            taskItem.updateElapsed()
        }
    }
}
