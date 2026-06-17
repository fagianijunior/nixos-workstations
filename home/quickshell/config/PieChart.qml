import QtQuick
import QtQuick.Layouts

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredWidth: 80
    implicitHeight: 80
    
    property string label: ""
    property color color: "cyan"
    property double value: 0 // 0.0 to 1.0

    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, parent.height * 0.7)
        height: width

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(centerX, centerY) - 5
            var startAngle = -Math.PI / 2 // Start from the top

            // Background circle
            ctx.beginPath()
            ctx.strokeStyle = "#444444"
            ctx.lineWidth = 8
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            ctx.stroke()

            // Foreground arc
            if (root.value > 0) {
                ctx.beginPath()
                ctx.strokeStyle = root.color
                ctx.lineWidth = 8
                var endAngle = startAngle + (2 * Math.PI * root.value)
                ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                ctx.stroke()
            }
        }
    }

    Text {
        text: (value * 100).toFixed(0) + "%"
        anchors.centerIn: canvas
        color: "white"
        font.pixelSize: Math.max(8, Math.min(10, canvas.width * 0.15))
        font.bold: true
    }

    Text {
        text: label
        anchors.top: canvas.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: "white"
        font.pixelSize: Math.max(9, Math.min(11, root.width * 0.12))
        elide: Text.ElideMiddle
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }

    Component.onCompleted: {
        canvas.requestPaint()
    }

    onValueChanged: {
        canvas.requestPaint()
    }
}
