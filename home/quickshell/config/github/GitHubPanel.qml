// GitHubPanel.qml - Main GitHub status panel
// Displays notifications count and owner-grouped repository cards

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: githubPanel

    // Visual properties - Catppuccin Macchiato
    color: Qt.rgba(36/255, 39/255, 58/255, 0.7)
    radius: 8
    implicitHeight: innerLayout.implicitHeight

    // ---- Data Layer ----

    GitHubDataManager {
        id: dataManager

        onDataUpdated: {
            rebuildOwnerModel()
        }

        onErrorOccurred: function(message) {
            console.error("GitHubPanel error:", message)
        }
    }

    // ---- Process for opening notifications URL ----

    Process {
        id: openNotificationsProcess
        command: ["xdg-open", "https://github.com/notifications"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("xdg-open notifications error:", this.text.trim())
                }
            }
        }
    }

    // ---- Layout ----

    ColumnLayout {
        id: innerLayout
        anchors.fill: parent
        anchors.margins: 0
        spacing: 4

        // Header section
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // Title
            Text {
                text: "GitHub"
                color: "#cad3f5"
                font.pixelSize: Math.max(14, Math.min(18, rootPanel.width * 0.07))
                font.bold: true
                Layout.fillWidth: true
            }

            // Status text (loading/error)
            Text {
                id: statusText
                text: {
                    if (dataManager.isLoading) {
                        return "Loading..."
                    } else if (dataManager.errorMessage !== "") {
                        return dataManager.errorMessage
                    } else {
                        return ""
                    }
                }
                color: dataManager.errorMessage !== "" ? "#f38ba8" : "#a6adc8"
                font.pixelSize: 9
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Manual refresh button
            Button {
                id: refreshButton
                text: "↻"
                implicitWidth: 24
                implicitHeight: 24
                onClicked: {
                    dataManager.refreshData()
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

        // Notifications section (clickable)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: notifRow.implicitHeight + 8
            color: notifMouseArea.containsMouse ? "#363a4f" : "transparent"
            radius: 4

            RowLayout {
                id: notifRow
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                Text {
                    text: "🔔"
                    font.pixelSize: 12
                }

                Text {
                    text: "Notifications"
                    color: "#cad3f5"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                }

                // Notification count badge
                Rectangle {
                    visible: dataManager.notificationCount > 0
                    Layout.preferredWidth: notifCountText.implicitWidth + 10
                    Layout.preferredHeight: 18
                    radius: 9
                    color: "#ed8796"

                    Text {
                        id: notifCountText
                        anchors.centerIn: parent
                        text: dataManager.notificationCount.toString()
                        color: "#24273a"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                // Zero state
                Text {
                    visible: dataManager.notificationCount === 0 && !dataManager.isLoading
                    text: "0"
                    color: "#6c7086"
                    font.pixelSize: 9
                }
            }

            MouseArea {
                id: notifMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    openNotificationsProcess.running = true
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#494d64"
            visible: ownerListView.count > 0
        }

        // Owner cards list (grouped by org/user)
        ListView {
            id: ownerListView
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight > 0 ? contentHeight : 0
            interactive: false
            spacing: 4

            model: ListModel {
                id: ownerModel
            }

            delegate: RepoCard {
                width: ownerListView.width
                ownerName: model.ownerName
                repos: JSON.parse(model.reposJson)
            }
        }

        // Empty state
        Text {
            visible: ownerListView.count === 0 && !dataManager.isLoading && dataManager.errorMessage === ""
            text: "No open PRs or Issues"
            color: "#6c7086"
            font.pixelSize: 9
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // ---- Helper Functions ----

    function rebuildOwnerModel() {
        ownerModel.clear()

        // Group repoData by owner
        let ownerMap = {}
        let repos = dataManager.repoData

        for (let i = 0; i < repos.length; i++) {
            let r = repos[i]
            let owner = r.owner
            if (!ownerMap[owner]) {
                ownerMap[owner] = []
            }
            ownerMap[owner].push({
                repoName: r.repoName,
                fullName: r.fullName,
                prCount: r.prCount,
                issueCount: r.issueCount
            })
        }

        // Sort owners: monitored scopes first, then alphabetical
        let ownerKeys = Object.keys(ownerMap)
        let monitoredNames = dataManager.monitoredScopes.map(function(s) {
            return s.replace(/^(org:|user:)/, "")
        })

        ownerKeys.sort(function(a, b) {
            let aIdx = monitoredNames.indexOf(a)
            let bIdx = monitoredNames.indexOf(b)
            // Monitored scopes first (by their config order)
            if (aIdx >= 0 && bIdx >= 0) return aIdx - bIdx
            if (aIdx >= 0) return -1
            if (bIdx >= 0) return 1
            return a.localeCompare(b)
        })

        for (let i = 0; i < ownerKeys.length; i++) {
            let owner = ownerKeys[i]
            ownerModel.append({
                ownerName: owner,
                reposJson: JSON.stringify(ownerMap[owner])
            })
        }

        console.log("GitHub owner model rebuilt:", ownerModel.count, "owners")
    }

    // Initial data load
    Component.onCompleted: {
        console.log("GitHubPanel initialized, loading data...")
        dataManager.refreshData()
    }
}
