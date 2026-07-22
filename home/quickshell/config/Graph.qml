import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: root
    spacing: 5
    
    Layout.fillWidth: true

    property string label: ""
    property color color: "lime"
    property color labelColor: "white"
    property string valueSuffix: ""
    property double maxValue: 100
    property var history: []
    property double currentValue: 0

    function addValue(val, valueSuffix) {
        if (val > 10000 && valueSuffix === " KB/s") {
            currentValue = (val / 1000).toFixed(2)
            valueSuffix = " MB/s"
        } else {
            currentValue = val
            valueSuffix = " KB/s"
        }

        history.push(val)
        if (history.length > 50) history.shift()
        canvas.requestPaint()
    }


    Item {
        Layout.fillWidth: true
        height: 30
        clip: true

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // borda
                ctx.strokeStyle = "white"
                ctx.lineWidth = 1
                ctx.strokeRect(0, 0, width, height)

                // linha do gráfico
                ctx.strokeStyle = root.color
                ctx.lineWidth = 2
                ctx.beginPath()
                for (var i = 0; i < history.length; i++) {
                    var x = (i / (history.length - 1)) * width
                    var y = height - (history[i] / maxValue) * height
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
            }
        }

        Text {
            text: label
            color: root.labelColor
            font.pixelSize: 12
            font.bold: true
            style: Text.Outline
            styleColor: "black"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.horizontalCenter
            anchors.leftMargin: 5
            anchors.topMargin: 5
            elide: Text.ElideRight
            z: 1
        }

        Text {
            text: currentValue.toFixed(1) + valueSuffix
            color: root.labelColor
            font.pixelSize: 12
            font.bold: true
            style: Text.Outline
            styleColor: "black"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.left: parent.horizontalCenter
            anchors.rightMargin: 5
            anchors.topMargin: 5
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            z: 1
        }
    }
}
