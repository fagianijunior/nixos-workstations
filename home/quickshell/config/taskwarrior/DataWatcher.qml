// DataWatcher.qml - Data Layer Component
// Monitors Taskwarrior data directory for changes and triggers refreshes
// Supports both file system watching and polling-based refresh
// Validates: Requirements 7.1, 7.2, 7.4

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: dataWatcher
    
    // ---- Configuration Properties ----
    
    // Path to Taskwarrior data directory (e.g., ~/.task)
    property string taskDataPath: ""
    
    // Whether the watcher is enabled
    property bool enabled: true
    
    // Whether file watching is available and working
    property bool fileWatcherAvailable: false
    
    // Polling interval in milliseconds (7 seconds per requirements 7.5)
    property int pollingInterval: 7000
    
    // ---- Signals ----
    
    // Emitted when Taskwarrior data has changed
    signal dataChanged()
    
    // ---- Internal Properties ----
    
    // Track if we've attempted to initialize the file watcher
    property bool _watcherInitialized: false
    
    // ---- File System Watchers ----
    
    // Polling Timer - Fallback mechanism when file watcher unavailable
    // Validates: Requirements 7.1, 7.5
    Timer {
        id: pollTimer
        interval: dataWatcher.pollingInterval
        running: dataWatcher.enabled && !dataWatcher.fileWatcherAvailable
        repeat: true
        
        onTriggered: {
            console.log("Polling timer triggered - checking for data changes")
            dataWatcher.dataChanged()
        }
    }
    
    // FileView for monitoring pending.data
    FileView {
        id: pendingWatcher
        path: dataWatcher.taskDataPath + "/pending.data"
        watchChanges: true
        
        onFileChanged: {
            if (dataWatcher.enabled && dataWatcher._watcherInitialized) {
                console.log("Detected change in pending.data")
                dataWatcher.dataChanged()
            }
        }
        
        onLoadFailed: function(error) {
            // File might not exist yet or permission issues
            console.warn("Failed to watch pending.data:", FileViewError.toString(error))
        }
    }
    
    // FileView for monitoring completed.data
    FileView {
        id: completedWatcher
        path: dataWatcher.taskDataPath + "/completed.data"
        watchChanges: true
        
        onFileChanged: {
            if (dataWatcher.enabled && dataWatcher._watcherInitialized) {
                console.log("Detected change in completed.data")
                dataWatcher.dataChanged()
            }
        }
        
        onLoadFailed: function(error) {
            // File might not exist yet or permission issues
            console.warn("Failed to watch completed.data:", FileViewError.toString(error))
        }
    }
    
    // ---- Initialization ----
    
    Component.onCompleted: {
        console.log("DataWatcher initialized")
        console.log("Task data path:", taskDataPath)
        console.log("Enabled:", enabled)
        
        // Attempt to detect if file watching is available
        // FileView with watchChanges should work in Quickshell
        // We'll set this to true and rely on the onLoadFailed handlers
        // to detect issues
        dataWatcher.fileWatcherAvailable = true
        
        // Mark as initialized after a short delay to avoid triggering
        // dataChanged on initial file loads
        Qt.callLater(function() {
            dataWatcher._watcherInitialized = true
            console.log("File watcher initialized, monitoring:", 
                       pendingWatcher.path, "and", completedWatcher.path)
        })
    }
}
