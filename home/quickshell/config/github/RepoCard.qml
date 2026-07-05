// RepoCard.qml - Owner/org card with expandable repo list
// Groups repositories by owner, shows repo names with PR/Issue badges

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: repoCard

    // Properties
    property string ownerName: ""
    property var repos: []  // Array of { repoName, fullName, prCount, issueCount }
    property bool isExpanded: false

    // Signal to notify parent
    signal expansionChanged(bool expanded)

    // Visual properties - Catppuccin Macchiato
    color: Qt.rgba(0.2, 0.2, 0.2, 0.7)
    radius: 5
    border.color: isExpanded ? "#89b4fa" : "#494d64"
    border.width: 1
    implicitHeight: cardLayout.implicitHeight

    // Process for opening URLs in browser
    Process {
        id: openUrlProcess
        command: []
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("xdg-open error:", this.text.trim())
                }
            }
        }
    }

    function openUrl(url) {
        openUrlProcess.command = ["xdg-open", url]
        openUrlProcess.running = true
    }

    // Total counts for header
    function totalPrs() {
        let total = 0
        for (let i = 0; i < repos.length; i++) total += repos[i].prCount
        return total
    }

    function totalIssues() {
        let total = 0
        for (let i = 0; i < repos.length; i++) total += repos[i].issueCount
        return total
    }

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        spacing: 0

        // Header (always visible, clickable)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    repoCard.isExpanded = !repoCard.isExpanded
                    repoCard.expansionChanged(repoCard.isExpanded)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                // Owner name
                Text {
                    text: repoCard.ownerName
                    color: "#cad3f5"
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 1
                }

                // Total PR count badge
                Rectangle {
                    visible: repoCard.totalPrs() > 0
                    Layout.preferredWidth: headerPrText.implicitWidth + 8
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#313244"

                    Text {
                        id: headerPrText
                        anchors.centerIn: parent
                        text: "PR " + repoCard.totalPrs()
                        color: "#a6e3a1"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                // Total Issue count badge
                Rectangle {
                    visible: repoCard.totalIssues() > 0
                    Layout.preferredWidth: headerIssueText.implicitWidth + 8
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#313244"

                    Text {
                        id: headerIssueText
                        anchors.centerIn: parent
                        text: "I " + repoCard.totalIssues()
                        color: "#f5a97f"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                // Repo count
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: repoCard.repos.length.toString()
                        color: "#89b4fa"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                // Expansion indicator
                Text {
                    text: repoCard.isExpanded ? "▼" : "▶"
                    color: "#89b4fa"
                    font.pixelSize: 8
                }
            }
        }

        // Repo list (visible only when expanded)
        Column {
            id: repoList
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: repoCard.isExpanded ? 6 : 0
            spacing: 2
            visible: repoCard.isExpanded

            Repeater {
                model: repoCard.repos

                delegate: Rectangle {
                    width: repoList.width
                    height: repoRow.implicitHeight + 4
                    color: "transparent"
                    radius: 3

                    RowLayout {
                        id: repoRow
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 4

                        // Repo name
                        Text {
                            text: modelData.repoName
                            color: "#b8c0e0"  // Subtext1
                            font.pixelSize: 9
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                            maximumLineCount: 1
                        }

                        // PR column (fixed width)
                        Item {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 14

                            Rectangle {
                                anchors.fill: parent
                                visible: modelData.prCount > 0
                                radius: 7
                                color: "#313244"

                                Text {
                                    anchors.centerIn: parent
                                    text: "PR " + modelData.prCount
                                    color: "#a6e3a1"
                                    font.pixelSize: 8
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        repoCard.openUrl("https://github.com/" + modelData.fullName + "/pulls?q=is%3Aopen")
                                    }
                                }
                            }
                        }

                        // Issue column (fixed width)
                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 14

                            Rectangle {
                                anchors.fill: parent
                                visible: modelData.issueCount > 0
                                radius: 7
                                color: "#313244"

                                Text {
                                    anchors.centerIn: parent
                                    text: "I " + modelData.issueCount
                                    color: "#f5a97f"
                                    font.pixelSize: 8
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        repoCard.openUrl("https://github.com/" + modelData.fullName + "/issues?q=is%3Aopen")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
