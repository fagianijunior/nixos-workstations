import QtQuick
import Quickshell.Io

QtObject {
    id: clickRedirectHandler
    
    // Signal emitted when redirection fails
    signal redirectFailed(string appName, string error)
    
    // Known application mappings for identification and launching
    property var knownApplications: {
        "firefox": { executable: "firefox", displayName: "Firefox" },
        "thunderbird": { executable: "thunderbird", displayName: "Thunderbird" },
        "discord": { executable: "discord", displayName: "Discord" },
        "spotify": { executable: "spotify", displayName: "Spotify" },
        "vscode": { executable: "code", displayName: "Visual Studio Code" },
        "chrome": { executable: "google-chrome", displayName: "Google Chrome" },
        "slack": { executable: "slack", displayName: "Slack" },
        "terminal": { executable: "gnome-terminal", displayName: "Terminal" },
        "nautilus": { executable: "nautilus", displayName: "Files" },
        "gimp": { executable: "gimp", displayName: "GIMP" },
        "code": { executable: "code", displayName: "Visual Studio Code" },
        "chromium": { executable: "chromium", displayName: "Chromium" },
        "telegram": { executable: "telegram-desktop", displayName: "Telegram" },
        "whatsapp": { executable: "whatsapp-for-linux", displayName: "WhatsApp" },
        "signal": { executable: "signal-desktop", displayName: "Signal" }
    }
    
    // Fuzzy matching mappings for common application name variations
    property var fuzzyMappings: {
        "firefox-esr": "firefox",
        "firefox-developer": "firefox", 
        "google-chrome": "chrome",
        "chromium-browser": "chromium",
        "visual-studio-code": "vscode",
        "gnome-terminal": "terminal",
        "konsole": "terminal",
        "alacritty": "terminal",
        "discord-canary": "discord",
        "discord-ptb": "discord",
        "telegram-desktop": "telegram",
        "whatsapp-for-linux": "whatsapp",
        "signal-desktop": "signal"
    }
    
    // Process for checking if application is running
    property var checkRunningProcess: Process {
        id: checkRunningProcess
        property string targetApp: ""
        property string notificationId: ""
        
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                if (output && output !== "") {
                    // Application is running, try to focus it
                    console.log("Application", checkRunningProcess.targetApp, "is running, attempting to focus")
                    focusApplication(checkRunningProcess.targetApp)
                } else {
                    // Application is not running, try to launch it
                    console.log("Application", checkRunningProcess.targetApp, "is not running, attempting to launch")
                    launchApplication(checkRunningProcess.targetApp)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Error checking if application is running:", this.text.trim())
                    // Fallback: try to launch the application
                    launchApplication(checkRunningProcess.targetApp)
                }
            }
        }
    }
    
    // Process for focusing running applications
    property var focusProcess: Process {
        id: focusProcess
        property string targetApp: ""
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Focus command completed for", focusProcess.targetApp)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Error focusing application:", this.text.trim())
                    redirectFailed(focusProcess.targetApp, "Failed to focus application: " + this.text.trim())
                }
            }
        }
    }
    
    // Process for launching applications
    property var launchProcess: Process {
        id: launchProcess
        property string targetApp: ""
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Launch command completed for", launchProcess.targetApp)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Error launching application:", this.text.trim())
                    redirectFailed(launchProcess.targetApp, "Failed to launch application: " + this.text.trim())
                }
            }
        }
    }
    
    /**
     * Main function to handle notification clicks
     * @param appName - The application name from the notification
     * @param notificationId - The notification ID (optional)
     */
    function handleNotificationClick(appName, notificationId) {
        console.log("Handling notification click for app:", appName, "notification:", notificationId)
        
        // Identify the application
        let identificationResult = identifyApplication(appName)
        
        if (!identificationResult.identified) {
            console.warn("Could not identify application:", appName)
            redirectFailed(appName, "Unknown application: " + appName)
            return
        }
        
        console.log("Identified application:", identificationResult.executable)
        
        // Check if the application is running
        checkRunningProcess.targetApp = identificationResult.executable
        checkRunningProcess.notificationId = notificationId || ""
        checkRunningProcess.command = ["pgrep", "-f", identificationResult.executable]
        checkRunningProcess.running = true
    }
    
    /**
     * Identify the application from the notification app name
     * @param appName - The application name from the notification
     * @returns Object with identification results
     */
    function identifyApplication(appName) {
        try {
            // Handle invalid input
            if (!appName || typeof appName !== 'string' || appName.trim() === '') {
                return {
                    identified: false,
                    appName: appName,
                    executable: null,
                    error: "Empty or invalid app name"
                }
            }
            
            // Normalize app name for lookup
            let normalizedAppName = appName.toLowerCase().trim()
            
            // Check if it's a known application
            if (knownApplications.hasOwnProperty(normalizedAppName)) {
                let appInfo = knownApplications[normalizedAppName]
                return {
                    identified: true,
                    appName: normalizedAppName,
                    executable: appInfo.executable,
                    displayName: appInfo.displayName
                }
            }
            
            // Attempt fuzzy matching for similar names
            let fuzzyMatch = attemptFuzzyMatch(normalizedAppName)
            if (fuzzyMatch) {
                return {
                    identified: true,
                    appName: fuzzyMatch.appName,
                    executable: fuzzyMatch.executable,
                    displayName: fuzzyMatch.displayName,
                    matchType: "fuzzy"
                }
            }
            
            // For unknown applications, try to generate a reasonable executable name
            let guessedExecutable = generateExecutableGuess(normalizedAppName)
            
            return {
                identified: guessedExecutable !== null,
                appName: normalizedAppName,
                executable: guessedExecutable,
                displayName: appName,
                matchType: "guess"
            }
            
        } catch (error) {
            return {
                identified: false,
                appName: appName,
                executable: null,
                error: error.toString()
            }
        }
    }
    
    /**
     * Attempt fuzzy matching for application names
     * @param appName - Normalized application name
     * @returns Object with matched application info or null
     */
    function attemptFuzzyMatch(appName) {
        // Check direct fuzzy mappings
        if (fuzzyMappings.hasOwnProperty(appName)) {
            let mappedName = fuzzyMappings[appName]
            if (knownApplications.hasOwnProperty(mappedName)) {
                return {
                    appName: mappedName,
                    executable: knownApplications[mappedName].executable,
                    displayName: knownApplications[mappedName].displayName
                }
            }
        }
        
        // Check for partial matches
        for (let knownApp in knownApplications) {
            if (appName.includes(knownApp) || knownApp.includes(appName)) {
                return {
                    appName: knownApp,
                    executable: knownApplications[knownApp].executable,
                    displayName: knownApplications[knownApp].displayName
                }
            }
        }
        
        return null
    }
    
    /**
     * Generate a reasonable executable name guess
     * @param appName - Normalized application name
     * @returns String with guessed executable name or null
     */
    function generateExecutableGuess(appName) {
        if (!appName || typeof appName !== 'string') {
            return null
        }
        
        // Clean up the app name to make it executable-like
        let cleaned = appName
            .toLowerCase()
            .replace(/[^a-z0-9\-_]/g, '-') // Replace special chars with dashes
            .replace(/--+/g, '-') // Replace multiple dashes with single dash
            .replace(/^-|-$/g, '') // Remove leading/trailing dashes
        
        return cleaned || null
    }
    
    /**
     * Focus a running application
     * @param executable - The executable name of the application
     * @returns Boolean indicating if focus command was initiated
     */
    function focusApplication(executable) {
        if (!executable) {
            console.error("Cannot focus application: no executable provided")
            return false
        }
        
        console.log("Attempting to focus application:", executable)
        
        // Use hyprctl to focus the application window on Hyprland
        focusProcess.targetApp = executable
        focusProcess.command = ["hyprctl", "dispatch", "focuswindow", "class:(?i)" + executable]
        focusProcess.running = true
        
        return true
    }
    
    /**
     * Launch an application
     * @param executable - The executable name of the application
     * @returns Boolean indicating if launch command was initiated
     */
    function launchApplication(executable) {
        if (!executable) {
            console.error("Cannot launch application: no executable provided")
            return false
        }
        
        console.log("Attempting to launch application:", executable)
        
        // Launch the application in the background
        launchProcess.targetApp = executable
        launchProcess.command = ["fish", "-c", `nohup ${executable} > /dev/null 2>&1 &`]
        launchProcess.running = true
        
        return true
    }
}