import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: taskPanel
    
    // Visual properties - Catppuccin Macchiato colors with transparency (matching shell style)
    color: Qt.rgba(36/255, 39/255, 58/255, 0.7)  // Base with transparency
    radius: 8
    implicitHeight: innerLayout.implicitHeight
    
    // Property to expose TaskManager to delegates
    property alias taskManagerRef: taskManager
    
    // ---- Data Layer Components ----
    
    TaskManager {
        id: taskManager
        refreshInterval: 7000
        useFileWatcher: true
        
        onTasksUpdated: {
            rebuildTaskCardModel()
        }
        
        onErrorOccurred: function(message) {
            console.error("TaskManager error:", message)
        }
        
        onTaskModified: function(uuid, success) {
            if (success) {
                console.log("Task modified successfully:", uuid)
            } else {
                console.error("Task modification failed:", uuid)
            }
        }
    }
    
    DataWatcher {
        id: dataWatcher
        taskDataPath: Quickshell.env("HOME") + "/.task"
        enabled: true
        pollingInterval: taskManager.refreshInterval
        
        onDataChanged: {
            console.log("Data change detected, refreshing tasks...")
            taskManager.refreshTasks()
        }
    }
    
    // Layout
    ColumnLayout {
        id: innerLayout
        anchors.fill: parent
        anchors.margins: 0
        spacing: 2
        
        // Header section
        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                text: "Tasks"
                color: "#cad3f5"
                font.pixelSize: Math.max(14, Math.min(18, rootPanel.width * 0.07))
                font.bold: true
                Layout.fillWidth: true
            }

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
                color: taskManager.errorMessage !== "" ? "#f38ba8" : "#a6adc8"
                font.pixelSize: 9
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
                
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
                color: "#89b4fa"
                font.pixelSize: 9
                font.bold: true
                visible: text !== ""
            }
            
            Button {
                id: refreshButton
                text: "↻"
                implicitWidth: 24
                implicitHeight: 24
                onClicked: {
                    taskManager.refreshTasks()
                }
                contentItem: Text {
                    text: refreshButton.text
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
        
        // Task cards list
        ListView {
            id: taskListView
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight > 0 ? contentHeight : 50
            interactive: false
            spacing: 5
            bottomMargin: 8
            
            model: ListModel {
                id: taskCardModel
            }
            
            delegate: TaskCard {
                id: cardDelegate
                width: taskListView.width
                clientName: model.clientName
                tasks: model.tasks
                taskManager: taskPanel.taskManagerRef
                
                onExpansionChanged: function(expanded) {
                    if (expanded) {
                        console.log("Card expanded:", clientName)
                        collapseOtherCards(cardDelegate)
                    }
                }
            }
        }
    }
    
    function collapseOtherCards(expandedCard) {
        for (let i = 0; i < taskListView.count; i++) {
            const item = taskListView.itemAtIndex(i)
            if (item && item !== expandedCard) {
                item.isExpanded = false
            }
        }
    }
    
    function rebuildTaskCardModel() {
        taskCardModel.clear()
        
        console.log("Rebuilding task card model...")
        console.log("tasksByClient:", JSON.stringify(Object.keys(taskManager.tasksByClient)))
        console.log("generalTasks count:", taskManager.generalTasks.length)
        
        for (const client in taskManager.tasksByClient) {
            const tasks = taskManager.tasksByClient[client]
            console.log("Adding card for client:", client, "with", tasks.length, "tasks")
            taskCardModel.append({
                clientName: client,
                tasks: JSON.stringify(tasks)
            })
        }
        
        if (taskManager.generalTasks.length > 0) {
            console.log("Adding general card with", taskManager.generalTasks.length, "tasks")
            taskCardModel.append({
                clientName: "General",
                tasks: JSON.stringify(taskManager.generalTasks)
            })
        }
        
        console.log("Task card model rebuilt:", taskCardModel.count, "cards")
    }
    
    Component.onCompleted: {
        console.log("TaskPanel initialized, loading tasks...")
        taskManager.refreshTasks()
    }
}
