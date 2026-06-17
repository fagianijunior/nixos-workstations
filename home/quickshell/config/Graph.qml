import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: root
    spacing: 5
    
    Layout.fillWidth: true

    property string label: ""
    property color color: "lime"
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


    Canvas {
        id: canvas
        Layout.fillWidth: true
        height: 30

    RowLayout {

        Layout.fillWidth: true
        Layout.fillHeight: true

        Text { 
            text: label
            color: "white"
            font.pixelSize: 12
            padding: 5
            Layout.alignment: Qt.AlignLeft
        }
        Text { 
            text: currentValue.toFixed(1) + valueSuffix
            color: "white"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignRight
            padding: 5
        }
    }
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
}
