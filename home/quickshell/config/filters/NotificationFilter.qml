import QtQuick
import Quickshell.Io
import "../utils"

QtObject {
    id: notificationFilter
    
    // Properties for filter configuration
    property var blockList: []
    property var allowList: []
    property string defaultBehavior: "allow"
    property string configName: "filters/filter-config"
    
    // Internal properties
    property bool configLoaded: false
    property var configManager: ConfigManager {
        id: configManager
        
        onConfigLoaded: function(name, config) {
            if (name === notificationFilter.configName) {
                if (config && config.version) {
                    notificationFilter.blockList = config.blockList || []
                    notificationFilter.allowList = config.allowList || []
                    notificationFilter.defaultBehavior = config.defaultBehavior || "allow"
                    notificationFilter.configLoaded = true
                    console.log("Notification filter config loaded:", 
                               "blockList:", notificationFilter.blockList.length,
                               "allowList:", notificationFilter.allowList.length,
                               "default:", notificationFilter.defaultBehavior)
                    console.log("config details:", config)
                } else {
                    console.log("No valid filter config found, using defaults")
                    notificationFilter.configLoaded = true
                }
            }
        }
        
        onConfigError: function(name, error) {
            if (name === notificationFilter.configName) {
                console.error("Failed to load notification filter config:", error)
                // Use default configuration
                notificationFilter.blockList = []
                notificationFilter.allowList = []
                notificationFilter.defaultBehavior = "allow"
                notificationFilter.configLoaded = true
            }
        }
    }
    
    // Load configuration on component creation
    Component.onCompleted: {
        // Ensure the filters directory exists
        configManager.ensureDirectory(configManager.configDirectory + "filters/")
        
        // Load config with default values
        let defaultConfig = {
            version: "1.0",
            blockList: [],
            allowList: [],
            defaultBehavior: "allow"
        }
        configManager.loadConfig(configName, defaultConfig)
    }
    
    // Main filter function - determines if notification should be displayed
    function shouldDisplayNotification(appName) {
        if (!configLoaded) {
            console.warn("Filter config not loaded yet, allowing notification from:", appName)
            return true
        }
        
        if (!appName || typeof appName !== 'string') {
            console.warn("Invalid app name provided to filter:", appName)
            return defaultBehavior === "allow"
        }
        
        // Priority order: allow list > block list > default behavior
        
        // Check allow list first (highest priority)
        if (allowList.indexOf(appName) !== -1) {
            console.log("Notification from", appName, "allowed by allow list")
            return true
        }
        
        // Check block list second
        if (blockList.indexOf(appName) !== -1) {
            console.log("Notification from", appName, "blocked by block list")
            return false
        }
        
        // Use default behavior if not in either list
        let decision = defaultBehavior === "allow"
        console.log("Notification from", appName, "using default behavior:", decision)
        return decision
    }
    
    // Add application to block list
    function addToBlockList(appName) {
        if (!appName || typeof appName !== 'string') {
            console.error("Invalid app name for block list:", appName)
            return false
        }
        
        // Remove from allow list if present
        removeFromAllowList(appName)
        
        // Add to block list if not already present
        if (blockList.indexOf(appName) === -1) {
            blockList.push(appName)
            console.log("Added", appName, "to block list")
            saveConfiguration()
            return true
        }
        
        console.log("App", appName, "already in block list")
        return false
    }
    
    // Add application to allow list
    function addToAllowList(appName) {
        if (!appName || typeof appName !== 'string') {
            console.error("Invalid app name for allow list:", appName)
            return false
        }
        
        // Remove from block list if present
        removeFromBlockList(appName)
        
        // Add to allow list if not already present
        if (allowList.indexOf(appName) === -1) {
            allowList.push(appName)
            console.log("Added", appName, "to allow list")
            saveConfiguration()
            return true
        }
        
        console.log("App", appName, "already in allow list")
        return false
    }
    
    // Remove application from block list
    function removeFromBlockList(appName) {
        let index = blockList.indexOf(appName)
        if (index !== -1) {
            blockList.splice(index, 1)
            console.log("Removed", appName, "from block list")
            return true
        }
        return false
    }
    
    // Remove application from allow list
    function removeFromAllowList(appName) {
        let index = allowList.indexOf(appName)
        if (index !== -1) {
            allowList.splice(index, 1)
            console.log("Removed", appName, "from allow list")
            return true
        }
        return false
    }
    
    // Remove application from all filter lists
    function removeFromFilters(appName) {
        let removedFromBlock = removeFromBlockList(appName)
        let removedFromAllow = removeFromAllowList(appName)
        
        if (removedFromBlock || removedFromAllow) {
            console.log("Removed", appName, "from all filter lists")
            saveConfiguration()
            return true
        }
        
        console.log("App", appName, "not found in any filter lists")
        return false
    }
    
    // Set default behavior
    function setDefaultBehavior(behavior) {
        if (behavior !== "allow" && behavior !== "block") {
            console.error("Invalid default behavior:", behavior)
            return false
        }
        
        if (defaultBehavior !== behavior) {
            defaultBehavior = behavior
            console.log("Default behavior changed to:", behavior)
            saveConfiguration()
            return true
        }
        
        return false
    }
    
    // Save current configuration to file
    function saveConfiguration() {
        let config = {
            version: "1.0",
            blockList: blockList.slice(), // Create copies of arrays
            allowList: allowList.slice(),
            defaultBehavior: defaultBehavior
        }
        
        configManager.saveConfig(configName, config)
    }
    
    // Reload configuration from file
    function reloadConfiguration() {
        console.log("Reloading notification filter configuration")
        let defaultConfig = {
            version: "1.0",
            blockList: [],
            allowList: [],
            defaultBehavior: "allow"
        }
        configManager.loadConfig(configName, defaultConfig)
    }
    
    // Get current filter statistics
    function getFilterStats() {
        return {
            blockListCount: blockList.length,
            allowListCount: allowList.length,
            defaultBehavior: defaultBehavior,
            configLoaded: configLoaded
        }
    }
    
    // Check if an app is in block list
    function isBlocked(appName) {
        return blockList.indexOf(appName) !== -1
    }
    
    // Check if an app is in allow list
    function isAllowed(appName) {
        return allowList.indexOf(appName) !== -1
    }
    
    // Get the reason why a notification would be displayed or blocked
    function getFilterReason(appName) {
        if (!appName || typeof appName !== 'string') {
            return "invalid_app_name"
        }
        
        if (allowList.indexOf(appName) !== -1) {
            return "allowed_by_list"
        }
        
        if (blockList.indexOf(appName) !== -1) {
            return "blocked_by_list"
        }
        
        return defaultBehavior === "allow" ? "allowed_by_default" : "blocked_by_default"
    }
}