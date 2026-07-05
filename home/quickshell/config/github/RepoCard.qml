// RepoCard.qml - Individual repository card
// Displays repo name with clickable PR and Issue counts

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: repoCard

    // Properties
    property string repoName: ""
    property string owner: ""
    property string fullName: ""
    property int prCount: 0
    property int issueCount: 0

    // Visual properties - Catppuccin Macchiato
    color: Qt.rgba(0.2, 0.2, 0.2, 0.7)
    radius: 5
    border.color: "#494d64"  // Surface1
    border.width: 1
    implicitHeight: cardLayout.implicitHeight + 12

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

    // Helper function to open URL
    function openUrl(url) {
        openUrlProcess.command = ["xdg-open", url]
        openUrlProcess.running = true
    }

    RowLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Repository name
        Text {
            id: repoNameText
            text: repoCard.fullName || repoCard.repoName
            color: "#cad3f5"  // Text
            font.pixelSize: 10
            elide: Text.ElideLeft
            Layout.fillWidth: true
            maximumLineCount: 1
        }

        // PR badge (clickable)
        Rectangle {
            visible: repoCard.prCount > 0
            Layout.preferredWidth: prBadgeRow.implicitWidth + 10
            Layout.preferredHeight: 18
            radius: 9
            color: "#313244"  // Surface0

            RowLayout {
                id: prBadgeRow
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "PR"
                    color: "#a6e3a1"  // Green
                    font.pixelSize: 9
                    font.bold: true
                }
                Text {
                    text: repoCard.prCount.toString()
                    color: "#a6e3a1"  // Green
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let url = "https://github.com/" + repoCard.fullName + "/pulls?q=is%3Aopen+author%3A%40me"
                    repoCard.openUrl(url)
                }
            }
        }

        // Issue badge (clickable)
        Rectangle {
            visible: repoCard.issueCount > 0
            Layout.preferredWidth: issueBadgeRow.implicitWidth + 10
            Layout.preferredHeight: 18
            radius: 9
            color: "#313244"  // Surface0

            RowLayout {
                id: issueBadgeRow
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "I"
                    color: "#f5a97f"  // Peach
                    font.pixelSize: 9
                    font.bold: true
                }
                Text {
                    text: repoCard.issueCount.toString()
                    color: "#f5a97f"  // Peach
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let url = "https://github.com/" + repoCard.fullName + "/issues?q=is%3Aopen+author%3A%40me"
                    repoCard.openUrl(url)
                }
            }
        }
    }
}
