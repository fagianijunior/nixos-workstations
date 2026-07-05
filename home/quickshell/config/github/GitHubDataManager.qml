// GitHubDataManager.qml - Data Layer Component
// Handles GitHub CLI command execution, JSON parsing, and data management
// Uses `gh` CLI for authentication and API access

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: githubDataManager

    // ---- Exposed Data Properties ----

    // Number of unread notifications
    property int notificationCount: 0

    // Array of repo objects: { repoName, owner, prCount, issueCount }
    property var repoData: []

    // Loading state indicator
    property bool isLoading: false

    // Error message from last operation (empty string if no error)
    property string errorMessage: ""

    // GitHub username (fetched on init)
    property string username: ""

    // ---- Configuration Properties ----

    // Refresh interval in milliseconds (default: 1 hour)
    property int refreshInterval: 3600000

    // ---- Signals ----

    // Emitted when data has been refreshed
    signal dataUpdated()

    // Emitted when an error occurs
    signal errorOccurred(string message)

    // ---- Internal State ----

    // Track which fetches have completed in current cycle
    property bool _notificationsDone: false
    property bool _prsDone: false
    property bool _issuesDone: false
    property var _prsRaw: []
    property var _issuesRaw: []

    // ---- Timer for Auto-Refresh ----

    Timer {
        id: autoRefreshTimer
        interval: githubDataManager.refreshInterval
        running: true
        repeat: true
        onTriggered: {
            githubDataManager.refreshData()
        }
    }

    // ---- Process: Fetch Username ----

    Process {
        id: usernameProcess
        command: ["gh", "api", "user", "--jq", ".login"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let result = this.text.trim()
                if (result && result !== "") {
                    githubDataManager.username = result
                    console.log("GitHub username:", result)
                    // Now fetch the actual data
                    fetchAllData()
                } else {
                    githubDataManager.errorMessage = "gh: no username returned"
                    githubDataManager.errorOccurred(githubDataManager.errorMessage)
                    githubDataManager.isLoading = false
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    githubDataManager.errorMessage = "gh auth error: " + this.text.trim()
                    githubDataManager.errorOccurred(githubDataManager.errorMessage)
                    githubDataManager.isLoading = false
                    console.error("GitHub username fetch error:", this.text.trim())
                }
            }
        }
    }

    // ---- Process: Fetch Notifications ----

    Process {
        id: notificationsProcess
        command: ["gh", "api", "notifications", "--jq", "length"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let result = this.text.trim()
                let count = parseInt(result)
                githubDataManager.notificationCount = isNaN(count) ? 0 : count
                githubDataManager._notificationsDone = true
                checkAllDone()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Notifications fetch error:", this.text.trim())
                    githubDataManager.notificationCount = 0
                    githubDataManager._notificationsDone = true
                    checkAllDone()
                }
            }
        }
    }

    // ---- Process: Fetch PRs ----

    Process {
        id: prsProcess
        command: ["gh", "search", "prs", "--author=@me", "--state=open", "archived:false", "--json", "repository"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    githubDataManager._prsRaw = Array.isArray(data) ? data : []
                } catch (e) {
                    console.error("PRs JSON parse error:", e)
                    githubDataManager._prsRaw = []
                }
                githubDataManager._prsDone = true
                checkAllDone()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("PRs fetch error:", this.text.trim())
                    githubDataManager._prsRaw = []
                    githubDataManager._prsDone = true
                    checkAllDone()
                }
            }
        }
    }

    // ---- Process: Fetch Issues ----

    Process {
        id: issuesProcess
        command: ["gh", "search", "issues", "--author=@me", "--state=open", "archived:false", "--json", "repository"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    githubDataManager._issuesRaw = Array.isArray(data) ? data : []
                } catch (e) {
                    console.error("Issues JSON parse error:", e)
                    githubDataManager._issuesRaw = []
                }
                githubDataManager._issuesDone = true
                checkAllDone()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Issues fetch error:", this.text.trim())
                    githubDataManager._issuesRaw = []
                    githubDataManager._issuesDone = true
                    checkAllDone()
                }
            }
        }
    }

    // ---- Public Methods ----

    function refreshData() {
        isLoading = true
        errorMessage = ""
        _notificationsDone = false
        _prsDone = false
        _issuesDone = false
        _prsRaw = []
        _issuesRaw = []

        if (username === "") {
            // Need to fetch username first
            usernameProcess.running = true
        } else {
            fetchAllData()
        }
    }

    // ---- Internal Methods ----

    function fetchAllData() {
        notificationsProcess.running = true
        prsProcess.running = true
        issuesProcess.running = true
    }

    function checkAllDone() {
        if (!_notificationsDone || !_prsDone || !_issuesDone) {
            return
        }

        // All fetches complete — aggregate by repository
        let repoMap = {}

        // Count PRs per repo
        for (let i = 0; i < _prsRaw.length; i++) {
            let pr = _prsRaw[i]
            if (pr.repository && pr.repository.nameWithOwner) {
                let key = pr.repository.nameWithOwner
                if (!repoMap[key]) {
                    repoMap[key] = { prCount: 0, issueCount: 0 }
                }
                repoMap[key].prCount++
            }
        }

        // Count Issues per repo
        for (let i = 0; i < _issuesRaw.length; i++) {
            let issue = _issuesRaw[i]
            if (issue.repository && issue.repository.nameWithOwner) {
                let key = issue.repository.nameWithOwner
                if (!repoMap[key]) {
                    repoMap[key] = { prCount: 0, issueCount: 0 }
                }
                repoMap[key].issueCount++
            }
        }

        // Convert to array
        let result = []
        for (let fullName in repoMap) {
            let parts = fullName.split("/")
            let owner = parts[0] || ""
            let repoName = parts[1] || fullName
            result.push({
                repoName: repoName,
                owner: owner,
                fullName: fullName,
                prCount: repoMap[fullName].prCount,
                issueCount: repoMap[fullName].issueCount
            })
        }

        // Sort by total activity (PRs + Issues) descending
        result.sort(function(a, b) {
            return (b.prCount + b.issueCount) - (a.prCount + a.issueCount)
        })

        githubDataManager.repoData = result
        githubDataManager.isLoading = false
        githubDataManager.dataUpdated()

        console.log("GitHub data refreshed:", notificationCount, "notifications,", result.length, "repos")
    }
}
