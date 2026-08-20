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
    
    // Header timer properties (removed - Timewarrior now tracks time)
    property bool hasActiveTaskInCard: hasActiveTask()
    
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
    
    // (formatTime and updateHeaderElapsed removed - Timewarrior handles time tracking)
    
    // Recalculate active state when task data changes
    onTaskArrayChanged: {
        hasActiveTaskInCard = hasActiveTask()
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
