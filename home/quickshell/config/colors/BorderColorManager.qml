import QtQuick

QtObject {
    id: borderColorManager
    
    // Catppuccin Macchiato color palette
    readonly property var catppuccinColors: ({
        "rosewater": "#f4dbd6",
        "flamingo": "#f0c6c6", 
        "pink": "#f5bde6",
        "mauve": "#c6a0f6",
        "red": "#ed8796",
        "maroon": "#ee99a0",
        "peach": "#f5a97f",
        "yellow": "#eed49f",
        "green": "#a6da95",
        "teal": "#8bd5ca",
        "sky": "#91d7e3",
        "sapphire": "#7dc4e4",
        "blue": "#8aadf4",
        "lavender": "#b7bdf8",
        "text": "#cad3f5",
        "subtext1": "#b8c0e0",
        "subtext0": "#a5adcb",
        "overlay2": "#939ab7",
        "overlay1": "#8087a2",
        "overlay0": "#6e738d",
        "surface2": "#5b6078",
        "surface1": "#494d64",
        "surface0": "#363a4f",
        "base": "#24273a",
        "mantle": "#1e2030",
        "crust": "#181926"
    })
    
    // Default category colors using Catppuccin Macchiato
    readonly property var categoryColors: ({
        "browser": "#8aadf4",
        "communication": "#a6da95",
        "media": "#f5a97f",
        "development": "#eed49f",
        "system": "#ed8796",
        "productivity": "#c6a0f6",
        "gaming": "#f5bde6",
        "utility": "#8bd5ca",
        "default": "#b7bdf8"
    })
    
    // Application-specific colors (hardcoded for now)
    readonly property var appColors: ({
        "firefox": "#8aadf4",
        "chrome": "#8aadf4",
        "chromium": "#8aadf4",
        "thunderbird": "#a6da95",
        "discord": "#c6a0f6",
        "spotify": "#f5a97f",
        "code": "#eed49f",
        "vscode": "#eed49f",
        "terminal": "#eed49f",
        "steam": "#f5bde6",
        "vlc": "#f5a97f",
        "libreoffice": "#c6a0f6",
        "gimp": "#f5bde6",
        "blender": "#f5a97f",
        "telegram": "#8bd5ca",
        "slack": "#a6da95",
        "teams": "#8aadf4",
        "zoom": "#8aadf4",
        "obs": "#ed8796",
        "audacity": "#f5a97f",
        "inkscape": "#c6a0f6",
        "krita": "#f5bde6",
        "system-settings": "#ed8796",
        "nautilus": "#8bd5ca",
        "dolphin": "#8bd5ca",
        "thunar": "#8bd5ca"
    })
    
    /**
     * Get the appropriate Catppuccin Macchiato color for an application
     * @param appName - The name of the application
     * @returns {string} - Hex color code
     */
    function getColorForApp(appName) {
        if (!appName) {
            return categoryColors.default
        }
        
        let normalizedAppName = appName.toLowerCase().trim()
        
        // Check if app has a specific configured color
        if (appColors[normalizedAppName]) {
            return appColors[normalizedAppName]
        }
        
        // Fallback to category-based color
        return getCategoryColor(normalizedAppName)
    }
    
    /**
     * Get category-based color for an application
     * @param appName - The normalized application name
     * @returns {string} - Hex color code
     */
    function getCategoryColor(appName) {
        // Browser applications
        if (appName.includes("firefox") || appName.includes("chrome") || 
            appName.includes("chromium") || appName.includes("safari") ||
            appName.includes("edge") || appName.includes("opera")) {
            return categoryColors.browser
        }
        
        // Communication applications
        if (appName.includes("discord") || appName.includes("telegram") ||
            appName.includes("slack") || appName.includes("teams") ||
            appName.includes("thunderbird") || appName.includes("mail") ||
            appName.includes("whatsapp") || appName.includes("signal")) {
            return categoryColors.communication
        }
        
        // Media applications
        if (appName.includes("spotify") || appName.includes("vlc") ||
            appName.includes("mpv") || appName.includes("youtube") ||
            appName.includes("netflix") || appName.includes("media") ||
            appName.includes("music") || appName.includes("video")) {
            return categoryColors.media
        }
        
        // Development applications
        if (appName.includes("code") || appName.includes("vim") ||
            appName.includes("emacs") || appName.includes("git") ||
            appName.includes("terminal") || appName.includes("console") ||
            appName.includes("ide") || appName.includes("atom") ||
            appName.includes("sublime")) {
            return categoryColors.development
        }
        
        // System applications
        if (appName.includes("system") || appName.includes("settings") ||
            appName.includes("control") || appName.includes("manager") ||
            appName.includes("monitor") || appName.includes("update")) {
            return categoryColors.system
        }
        
        // Productivity applications
        if (appName.includes("office") || appName.includes("word") ||
            appName.includes("excel") || appName.includes("powerpoint") ||
            appName.includes("libreoffice") || appName.includes("calc") ||
            appName.includes("writer") || appName.includes("impress")) {
            return categoryColors.productivity
        }
        
        // Gaming applications
        if (appName.includes("steam") || appName.includes("game") ||
            appName.includes("epic") || appName.includes("origin") ||
            appName.includes("uplay") || appName.includes("battle")) {
            return categoryColors.gaming
        }
        
        // Utility applications
        if (appName.includes("file") || appName.includes("archive") ||
            appName.includes("zip") || appName.includes("backup") ||
            appName.includes("sync") || appName.includes("clean")) {
            return categoryColors.utility
        }
        
        // Default fallback
        return categoryColors.default
    }
    
    /**
     * Get all available Catppuccin Macchiato colors
     * @returns {object} - Object with color names and hex values
     */
    function getAvailableColors() {
        return catppuccinColors
    }
    
    /**
     * Check if a color is a valid Catppuccin Macchiato color
     * @param color - The color to check
     * @returns {boolean} - True if valid
     */
    function isValidCatppuccinColor(color) {
        return Object.values(catppuccinColors).includes(color)
    }
}