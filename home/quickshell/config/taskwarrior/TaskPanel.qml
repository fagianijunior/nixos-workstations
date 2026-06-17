import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: taskPanel
    
    // Visual properties - Catppuccin Macchiato colors with transparency (matching shell style)
    color: Qt.rgba(36/255, 39/255, 58/255, 0.7)  // Base with transparency
    radius: 8
    
    // Property to expose TaskManager to delegates
    property alias taskManagerRef: taskManager
    
    // ---- Data Layer Components (Task 8.2) ----
    
    // TaskManager - Handles Taskwarrior command execution and data management
    TaskManager {
        id: taskManager
        refreshInterval: 7000
        useFileWatcher: true
        
        // Signal: tasksUpdated - Rebuild UI model when tasks are refreshed
        onTasksUpdated: {
            rebuildTaskCardModel()
        }
        
        // Signal: errorOccurred - Log error messages
        onErrorOccurred: function(message) {
            console.error("TaskManager error:", message)
        }
        
        // Signal: taskModified - Handle task modification results
        onTaskModified: function(uuid, success) {
            if (success) {
                console.log("Task modified successfully:", uuid)
            } else {
                console.error("Task modification failed:", uuid)
            }
        }
    }
    
    // DataWatcher - Monitors ~/.task directory for changes
    DataWatcher {
        id: dataWatcher
        taskDataPath: Quickshell.env("HOME") + "/.task"
        enabled: true
        pollingInterval: taskManager.refreshInterval
        
        // KEY CONNECTION: Wire dataChanged signal to TaskManager.refreshTasks()
        onDataChanged: {
            console.log("Data change detected, refreshing tasks...")
            taskManager.refreshTasks()
        }
    }
    
    // Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0  // Reduced from 16
        spacing: 2  // Reduced from 12
        
        // Header section
        RowLayout {
            Layout.fillWidth: true
            spacing: 2  // Reduced from 12
            
            // Title
            Text {
                text: "Tasks"
                color: "#cad3f5"  // Text
                font.pixelSize: Math.max(14, Math.min(18, rootPanel.width * 0.07))
                font.bold: true
                Layout.fillWidth: true
            }

            // Loading/error/status text
            Text {
                id: statusText
                text: {
                    if (taskManager.isLoading) {
                        return "Loading..."
                    } else if (taskManager.errorMessage !== "") {
                        return taskManager.errorMessage
                    } else {
                        return ""
                    }
                }
                color: taskManager.errorMessage !== "" ? "#f38ba8" : "#a6adc8"  // Red for errors, Subtext for normal
                font.pixelSize: 9  // Reduced from 12
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
                
                // Tooltip for truncated error messages
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    visible: statusText.truncated && taskManager.errorMessage !== ""
                    
                    property var tooltip: null
                    
                    onEntered: {
                        if (!tooltip && taskManager.errorMessage !== "") {
                            tooltip = Qt.createQmlObject(`
                                import QtQuick
                                import QtQuick.Controls
                                ToolTip {
                                    background: Rectangle {
                                        color: "#24273a"
                                        border.color: "#f38ba8"
                                        border.width: 1
                                        radius: 4
                                    }
                                    contentItem: Text {
                                        text: "${taskManager.errorMessage.replace(/"/g, '\\"').replace(/\n/g, ' ')}"
                                        color: "#cad3f5"
                                        font.pixelSize: 11
                                        padding: 8
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            `, parent)
                        }
                        if (tooltip) tooltip.visible = true
                    }
                    onExited: {
                        if (tooltip) tooltip.visible = false
                    }
                }
            }
            
            // Task count indicator (shown when loaded)
            Text {
                id: taskCountText
                text: {
                    if (taskManager.isLoading) return ""
                    let clientCount = Object.keys(taskManager.tasksByClient).length
                    let generalCount = taskManager.generalTasks.length
                    let totalTasks = 0
                    for (let client in taskManager.tasksByClient) {
                        totalTasks += taskManager.tasksByClient[client].length
                    }
                    totalTasks += generalCount
                    return totalTasks > 0 ? totalTasks + " tasks" : ""
                }
                color: "#89b4fa"  // Blue
                font.pixelSize: 9  // Reduced from 12
                font.bold: true
                visible: text !== ""
            }
            
            // Manual refresh button
            Button {
                id: refreshButton
                text: "↻"
                onClicked: {
                    // Connected to TaskManager.refreshTasks() (Task 8.2)
                    taskManager.refreshTasks()
                }
                contentItem: Text {
                    text: refreshEventsButton.text
                    color: "#cad3f5"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: parent.pressed ? "#585b70" : "#313244" // Surface1 : Surface0
                    border.color: "#6c7086" // Surface2
                    radius: 5
                }
            }
        }
        
        // Task cards list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            
            ListView {
                id: taskListView
                spacing: 5
                bottomMargin: 8  // Add padding at the bottom
                
                // Placeholder model - will be populated from TaskManager in Task 8.2
                model: ListModel {
                    id: taskCardModel
                }
                
                // Delegate will use TaskCard component
                delegate: TaskCard {
                    id: cardDelegate
                    width: taskListView.width
                    clientName: model.clientName
                    tasks: model.tasks
                    taskManager: taskPanel.taskManagerRef  // Pass TaskManager reference via property alias
                    
                    // Handle expansion - collapse other cards (Task 8.5)
                    onExpansionChanged: function(expanded) {
                        if (expanded) {
                            console.log("Card expanded:", clientName)
                            // Collapse all other cards (single-focus behavior)
                            collapseOtherCards(cardDelegate)
                        }
                    }
                }
            }
        }
    }
    
    // ---- Helper Functions (Task 8.2, 8.3, 8.5) ----
    
    // Collapse all cards except the specified one (Task 8.5)
    function collapseOtherCards(expandedCard) {
        // Iterate through all items in the ListView
        for (let i = 0; i < taskListView.count; i++) {
            const item = taskListView.itemAtIndex(i)
            if (item && item !== expandedCard) {
                // Collapse this card
                item.isExpanded = false
            }
        }
    }
    
    // Rebuild task card model from TaskManager data
    function rebuildTaskCardModel() {
        taskCardModel.clear()
        
        console.log("Rebuilding task card model...")
        console.log("tasksByClient:", JSON.stringify(Object.keys(taskManager.tasksByClient)))
        console.log("generalTasks count:", taskManager.generalTasks.length)
        
        // Add client-specific cards
        for (const client in taskManager.tasksByClient) {
            const tasks = taskManager.tasksByClient[client]
            console.log("Adding card for client:", client, "with", tasks.length, "tasks")
            taskCardModel.append({
                clientName: client,
                tasks: JSON.stringify(tasks)  // Serialize as JSON string
            })
        }
        
        // Add general card if there are tasks without client
        if (taskManager.generalTasks.length > 0) {
            console.log("Adding general card with", taskManager.generalTasks.length, "tasks")
            taskCardModel.append({
                clientName: "General",
                tasks: JSON.stringify(taskManager.generalTasks)  // Serialize as JSON string
            })
        }
        
        console.log("Task card model rebuilt:", taskCardModel.count, "cards")
    }
    
    // Initial data load on component completion
    Component.onCompleted: {
        console.log("TaskPanel initialized, loading tasks...")
        taskManager.refreshTasks()
    }
}
