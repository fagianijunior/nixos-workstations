import QtQuick
import Quickshell.Io

QtObject {
    id: configManager
    
    // Properties
    property string configDirectory: ""
    property var loadedConfigs: ({})
    
    // Signals
    signal configLoaded(string configName, var configData)
    signal configSaved(string configName)
    signal configError(string configName, string error)
    
    // Initialize with the quickshell config directory
    Component.onCompleted: {
        configDirectory = Qt.resolvedUrl(".").toString().replace("file://", "")
        console.log("ConfigManager initialized with directory:", configDirectory)
    }
    
    // Load a JSON configuration file
    function loadConfig(configName, defaultConfig) {
        let filePath = configDirectory + configName + ".json"
        
        let readProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["cat", "${filePath}"]
                property string configName: "${configName}"
                property var defaultConfig: ${JSON.stringify(defaultConfig || {})}
                
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let configData = JSON.parse(this.text)
                            configManager.loadedConfigs[parent.configName] = configData
                            configManager.configLoaded(parent.configName, configData)
                            console.log("Config loaded successfully:", parent.configName)
                        } catch (e) {
                            console.warn("Failed to parse config", parent.configName, ":", e.toString())
                            // Use default config on parse error
                            configManager.loadedConfigs[parent.configName] = parent.defaultConfig
                            configManager.configLoaded(parent.configName, parent.defaultConfig)
                        }
                    }
                }
                
                stderr: StdioCollector {
                    onStreamFinished: {
                        if (this.text.trim() !== "") {
                            console.warn("Config file not found or error reading:", parent.configName)
                            // Use default config if file doesn't exist
                            configManager.loadedConfigs[parent.configName] = parent.defaultConfig
                            configManager.configLoaded(parent.configName, parent.defaultConfig)
                        }
                    }
                }
            }
        `, configManager)
        
        readProcess.running = true
        return readProcess
    }
    
    // Save a JSON configuration file
    function saveConfig(configName, configData) {
        let filePath = configDirectory + configName + ".json"
        let jsonString = JSON.stringify(configData, null, 2)
        
        // Create a temporary process to write the file
        let writeProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["bash", "-c", "echo '${jsonString.replace(/'/g, "'\\''")}' > '${filePath}'"]
                property string configName: "${configName}"
                
                stdout: StdioCollector {
                    onStreamFinished: {
                        configManager.loadedConfigs[parent.configName] = ${JSON.stringify(configData)}
                        configManager.configSaved(parent.configName)
                        console.log("Config saved successfully:", parent.configName)
                    }
                }
                
                stderr: StdioCollector {
                    onStreamFinished: {
                        if (this.text.trim() !== "") {
                            configManager.configError(parent.configName, "Failed to save: " + this.text.trim())
                            console.error("Failed to save config", parent.configName, ":", this.text.trim())
                        }
                    }
                }
            }
        `, configManager)
        
        writeProcess.running = true
        return writeProcess
    }
    
    // Get a loaded configuration
    function getConfig(configName) {
        return loadedConfigs[configName] || {}
    }
    
    // Check if a configuration is loaded
    function hasConfig(configName) {
        return loadedConfigs.hasOwnProperty(configName)
    }
    
    // Validate configuration structure
    function validateConfig(configData, requiredFields) {
        if (!configData || typeof configData !== 'object') {
            return { valid: false, error: "Config data is not an object" }
        }
        
        if (!requiredFields || !Array.isArray(requiredFields)) {
            return { valid: true, error: "" }
        }
        
        for (let i = 0; i < requiredFields.length; i++) {
            let field = requiredFields[i]
            if (!configData.hasOwnProperty(field)) {
                return { 
                    valid: false, 
                    error: "Missing required field: " + field 
                }
            }
        }
        
        return { valid: true, error: "" }
    }
    
    // Create directory if it doesn't exist
    function ensureDirectory(dirPath) {
        let mkdirProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["mkdir", "-p", "${dirPath}"]
                
                stderr: StdioCollector {
                    onStreamFinished: {
                        if (this.text.trim() !== "") {
                            console.error("Failed to create directory:", this.text.trim())
                        }
                    }
                }
            }
        `, configManager)
        
        mkdirProcess.running = true
        return mkdirProcess
    }
    
    // Get the full path for a config file
    function getConfigPath(configName) {
        return configDirectory + configName + ".json"
    }
    
    // List all available config files
    function listConfigs() {
        let listProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["find", "${configDirectory}", "-name", "*.json", "-type", "f"]
                
                stdout: StdioCollector {
                    onStreamFinished: {
                        let files = this.text.trim().split('\\n').filter(f => f.length > 0)
                        let configNames = files.map(f => {
                            let basename = f.split('/').pop()
                            return basename.replace('.json', '')
                        })
                        console.log("Available configs:", configNames)
                    }
                }
            }
        `, configManager)
        
        listProcess.running = true
        return listProcess
    }
}