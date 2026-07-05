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

    // Monitored scopes: orgs and users to show ALL open PRs/Issues
    // (not just authored by @me)
    property var monitoredScopes: ["org:Veezor", "user:fagianijunior", "user:fagiani"]

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

    // Track scoped fetches (additional queries for monitored orgs/users)
    property int _scopedPrsPending: 0
    property int _scopedIssuesPending: 0

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

    // ---- Process: Fetch personal PRs (--author=@me) ----

    Process {
        id: prsProcess
        command: ["gh", "search", "prs", "--author=@me", "--state=open", "archived:false", "--json", "repository,url"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (Array.isArray(data)) {
                        githubDataManager._prsRaw = githubDataManager._prsRaw.concat(data)
                    }
                } catch (e) {
                    console.error("PRs JSON parse error:", e)
                }
                githubDataManager._prsDone = true
                checkAllDone()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("PRs fetch error:", this.text.trim())
                    githubDataManager._prsDone = true
                    checkAllDone()
                }
            }
        }
    }

    // ---- Process: Fetch personal Issues (--author=@me) ----

    Process {
        id: issuesProcess
        command: ["gh", "search", "issues", "--author=@me", "--state=open", "archived:false", "--json", "repository,url"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (Array.isArray(data)) {
                        githubDataManager._issuesRaw = githubDataManager._issuesRaw.concat(data)
                    }
                } catch (e) {
                    console.error("Issues JSON parse error:", e)
                }
                githubDataManager._issuesDone = true
                checkAllDone()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Issues fetch error:", this.text.trim())
                    githubDataManager._issuesDone = true
                    checkAllDone()
                }
            }
        }
    }

    // ---- Dynamic Process for scoped PR queries ----

    Process {
        id: scopedPrsProcess
        command: []
        running: false

        property int currentIndex: 0

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (Array.isArray(data)) {
                        githubDataManager._prsRaw = githubDataManager._prsRaw.concat(data)
                    }
                } catch (e) {
                    console.error("Scoped PRs JSON parse error:", e)
                }
                scopedPrsProcess.currentIndex++
                fetchNextScopedPrs()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Scoped PRs fetch error:", this.text.trim())
                }
                scopedPrsProcess.currentIndex++
                fetchNextScopedPrs()
            }
        }
    }

    // ---- Dynamic Process for scoped Issue queries ----

    Process {
        id: scopedIssuesProcess
        command: []
        running: false

        property int currentIndex: 0

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (Array.isArray(data)) {
                        githubDataManager._issuesRaw = githubDataManager._issuesRaw.concat(data)
                    }
                } catch (e) {
                    console.error("Scoped Issues JSON parse error:", e)
                }
                scopedIssuesProcess.currentIndex++
                fetchNextScopedIssues()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Scoped Issues fetch error:", this.text.trim())
                }
                scopedIssuesProcess.currentIndex++
                fetchNextScopedIssues()
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
        _scopedPrsPending = monitoredScopes.length
        _scopedIssuesPending = monitoredScopes.length
        scopedPrsProcess.currentIndex = 0
        scopedIssuesProcess.currentIndex = 0

        if (username === "") {
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

        // Start scoped fetches sequentially
        fetchNextScopedPrs()
        fetchNextScopedIssues()
    }

    function fetchNextScopedPrs() {
        if (scopedPrsProcess.currentIndex >= monitoredScopes.length) {
            // All scoped PR fetches done
            _scopedPrsPending = 0
            checkAllDone()
            return
        }

        let scope = monitoredScopes[scopedPrsProcess.currentIndex]
        scopedPrsProcess.command = ["gh", "search", "prs", "--state=open", "archived:false", scope, "--json", "repository,url"]
        scopedPrsProcess.running = true
    }

    function fetchNextScopedIssues() {
        if (scopedIssuesProcess.currentIndex >= monitoredScopes.length) {
            // All scoped Issue fetches done
            _scopedIssuesPending = 0
            checkAllDone()
            return
        }

        let scope = monitoredScopes[scopedIssuesProcess.currentIndex]
        scopedIssuesProcess.command = ["gh", "search", "issues", "--state=open", "archived:false", scope, "--json", "repository,url"]
        scopedIssuesProcess.running = true
    }

    function checkAllDone() {
        if (!_notificationsDone || !_prsDone || !_issuesDone) {
            return
        }
        if (_scopedPrsPending > 0 || _scopedIssuesPending > 0) {
            return
        }

        // All fetches complete — deduplicate and aggregate by repository
        let repoMap = {}

        // Count PRs per repo (deduplicated by nameWithOwner)
        let seenPrs = {}
        for (let i = 0; i < _prsRaw.length; i++) {
            let pr = _prsRaw[i]
            if (pr.repository && pr.repository.nameWithOwner) {
                let key = pr.repository.nameWithOwner

                // Deduplicate: use a composite key if url available, else just count
                let prId = (pr.url || "") + key + i.toString()
                if (pr.url && seenPrs[pr.url]) continue
                if (pr.url) seenPrs[pr.url] = true

                if (!repoMap[key]) {
                    repoMap[key] = { prCount: 0, issueCount: 0 }
                }
                repoMap[key].prCount++
            }
        }

        // Count Issues per repo (deduplicated)
        let seenIssues = {}
        for (let i = 0; i < _issuesRaw.length; i++) {
            let issue = _issuesRaw[i]
            if (issue.repository && issue.repository.nameWithOwner) {
                let key = issue.repository.nameWithOwner

                let issueId = (issue.url || "") + key + i.toString()
                if (issue.url && seenIssues[issue.url]) continue
                if (issue.url) seenIssues[issue.url] = true

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
