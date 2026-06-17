import QtQuick
import QtQuick.Layouts

Rectangle {
    id: taskCard
    
    // Properties
    property string clientName: ""
    property var tasks: []
    property bool isExpanded: false
    property var taskManager: null  // Reference to TaskManager for child components
    
    // Internal property to hold deserialized tasks array
    property var taskArray: []
    
    // Header timer properties
    property int headerElapsedSeconds: 0
    property bool hasActiveTaskInCard: hasActiveTask()
    property bool hasAnyTimeInCard: headerElapsedSeconds > 0
    
    // Signal to notify parent when expansion state changes
    signal expansionChanged(bool expanded)
    
    // Deserialize tasks when the property changes
    onTasksChanged: {
        if (typeof tasks === "string") {
            try {
                taskArray = JSON.parse(tasks)
                console.log("TaskCard deserialized tasks for", clientName, "- count:", taskArray.length)
            } catch (e) {
                console.error("Failed to parse tasks JSON:", e)
                taskArray = []
            }
        } else if (Array.isArray(tasks)) {
            taskArray = tasks
        } else {
            taskArray = []
        }
    }
    
    // Debug: Log when taskManager changes
    onTaskManagerChanged: {
        console.log("TaskCard", clientName, "- taskManager changed:", taskManager)
    }
    
    // Visual properties
    color: Qt.rgba(0.2, 0.2, 0.2, 0.7)  // Transparent background matching notifications
    radius: 5  // Reduced from 8
    border.color: isExpanded ? "#89b4fa" : "#555555"  // Blue when expanded, subtle otherwise
    border.width: 1
    
    // Explicit height management
    implicitHeight: isExpanded ? 40 + taskListContainer.implicitHeight : 40  // Reduced from 60
    height: implicitHeight
    
    // States for compact and expanded modes
    states: [
        State {
            name: "compact"
            when: !isExpanded
        },
        State {
            name: "expanded"
            when: isExpanded
        }
    ]
    
    // Transition with height animation
    transitions: Transition {
        NumberAnimation {
            properties: "height"
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
    
    // Helper function to check if any task has high priority
    function hasHighPriorityTask() {
        if (!taskArray || taskArray.length === 0) {
            return false
        }
        
        for (var i = 0; i < taskArray.length; i++) {
            if (taskArray[i].priority === "H") {
                return true
            }
        }
        
        return false
    }
    
    // Helper function to check if any task is active
    function hasActiveTask() {
        if (!taskArray || taskArray.length === 0) {
            return false
        }
        
        for (var i = 0; i < taskArray.length; i++) {
            if (taskArray[i].start !== undefined && taskArray[i].start !== "") {
                return true
            }
        }
        
        return false
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
    
    // Format seconds as HH:MM:SS
    function formatTime(totalSeconds) {
        if (totalSeconds < 0) totalSeconds = 0
        var hours   = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var seconds = totalSeconds % 60
        var hh = hours.toString(); if (hh.length < 2) hh = "0" + hh
        var mm = minutes.toString(); if (mm.length < 2) mm = "0" + mm
        var ss = seconds.toString(); if (ss.length < 2) ss = "0" + ss
        return hh + ":" + mm + ":" + ss
    }
    
    // Calculate total elapsed for ALL tasks in this card (sum of totalactivetime + active session)
    function updateHeaderElapsed() {
        var total = 0
        for (var i = 0; i < taskArray.length; i++) {
            var t = taskArray[i]
            var accumulated = 0
            if (t.totalactivetime) {
                accumulated = parseInt(t.totalactivetime)
                if (isNaN(accumulated)) accumulated = 0
            }
            total += accumulated
            // If this task is active, add the current session time
            if (t.start !== undefined && t.start !== "") {
                var startMs = parseTaskwarriorTimestamp(t.start)
                if (startMs > 0) {
                    var session = Math.floor((Date.now() - startMs) / 1000)
                    if (session < 0) session = 0
                    total += session
                }
            }
        }
        headerElapsedSeconds = total
    }
    
    // Recalculate header elapsed when task data changes
    onTaskArrayChanged: {
        updateHeaderElapsed()
    }
    
    // Header timer — ticks every 1 second while an active task exists in this card
    Timer {
        id: headerTimer
        interval: 1000
        running: taskCard.hasActiveTaskInCard
        repeat: true
        onTriggered: taskCard.updateHeaderElapsed()
    }
    
    // Content layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header (always visible)
        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 40  // Reduced from 60
            color: "transparent"
            
            // MouseArea for click handling
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    taskCard.isExpanded = !taskCard.isExpanded
                    taskCard.expansionChanged(taskCard.isExpanded)
                }
                cursorShape: Qt.PointingHandCursor
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8  // Reduced from 16
                anchors.rightMargin: 8  // Reduced from 16
                spacing: 6  // Reduced from 12
                
                // Client name
                Text {
                    id: clientNameText
                    text: taskCard.clientName || "General"
                    color: "#cad3f5"
                    font.pixelSize: 11  // Reduced from 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 1
                    
                    // Tooltip for truncated text
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        visible: clientNameText.truncated
                        propagateComposedEvents: true
                        
                        property var tooltip: null
                        
                        Component.onCompleted: {
                            tooltip = Qt.createQmlObject(`
                                import QtQuick
                                import QtQuick.Controls
                                ToolTip {
                                    background: Rectangle {
                                        color: "#24273a"
                                        border.color: "#89b4fa"
                                        border.width: 1
                                        radius: 4
                                    }
                                    contentItem: Text {
                                        text: "${(taskCard.clientName || "General").replace(/"/g, '\\"')}"
                                        color: "#cad3f5"
                                        font.pixelSize: 11
                                        padding: 8
                                    }
                                }
                            `, parent)
                        }
                        
                        onEntered: {
                            if (tooltip) tooltip.visible = true
                        }
                        onExited: {
                            if (tooltip) tooltip.visible = false
                        }
                        onClicked: function(mouse) {
                            mouse.accepted = false
                        }
                    }
                }
                
                // Active task indicator
                Text {
                    visible: taskCard.hasActiveTask()
                    text: "▶"
                    color: "#89b4fa"
                    font.pixelSize: 8
                }
                
                // Header timer display (total time for all tasks in card)
                Text {
                    visible: taskCard.hasAnyTimeInCard
                    text: taskCard.formatTime(taskCard.headerElapsedSeconds)
                    color: "#a6e3a1"
                    font.pixelSize: 9
                    font.family: "monospace"
                }
                
                // Task count badge
                Rectangle {
                    Layout.preferredWidth: 24  // Reduced from 32
                    Layout.preferredHeight: 18  // Reduced from 24
                    radius: 9  // Reduced from 12
                    color: "#313244"
                    
                    Text {
                        anchors.centerIn: parent
                        text: taskCard.taskArray ? taskCard.taskArray.length : 0
                        color: "#89b4fa"
                        font.pixelSize: 10  // Reduced from 12
                        font.bold: true
                    }
                }
                
                // Priority indicator (red dot for high-priority tasks)
                Rectangle {
                    visible: taskCard.hasHighPriorityTask()
                    Layout.preferredWidth: 6  // Reduced from 8
                    Layout.preferredHeight: 6  // Reduced from 8
                    radius: 3  // Reduced from 4
                    color: "#f38ba8"  // Catppuccin red
                }
                
                // Expansion indicator
                Text {
                    text: taskCard.isExpanded ? "▼" : "▶"
                    color: "#89b4fa"
                    font.pixelSize: 8  // Reduced from 10
                }
            }
        }
        
        // Task list container (visible only when expanded)
        Item {
            id: taskListContainer
            Layout.fillWidth: true
            implicitHeight: taskCard.isExpanded ? taskColumn.implicitHeight + 6 : 0
            Layout.preferredHeight: implicitHeight
            visible: taskCard.isExpanded
            clip: true
            
            Column {
                id: taskColumn
                anchors.fill: parent
                anchors.leftMargin: 8  // Reduced from 16
                anchors.rightMargin: 8  // Reduced from 16
                anchors.bottomMargin: 12  // Increased to prevent overlap
                spacing: 2  // Reduced from 4
                
                Repeater {
                    model: taskCard.taskArray
                    
                    delegate: TaskItem {
                        width: taskColumn.width
                        task: modelData
                        taskManager: taskCard.taskManager
                    }
                }
            }
        }
    }
}
