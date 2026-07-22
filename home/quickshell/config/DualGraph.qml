import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: root
    spacing: 5

    Layout.fillWidth: true

    property string label1: ""
    property string label2: ""
    property color color1: "lime"
    property color color2: "cyan"
    property string valueSuffix: ""
    property double maxValue: 100
    property var history1: []
    property var history2: []
    property double currentValue1: 0
    property double currentValue2: 0
    property string displayLabel1: ""
    property string displayLabel2: ""

    function addValue1(val) {
        currentValue1 = val
        history1.push(val)
        if (history1.length > 50) history1.shift()
        canvas.requestPaint()
    }

    function addValue2(val) {
        currentValue2 = val
        history2.push(val)
        if (history2.length > 50) history2.shift()
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

                // linha 1
                if (history1.length > 1) {
                    ctx.strokeStyle = root.color1
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    for (var i = 0; i < history1.length; i++) {
                        var x = (i / (history1.length - 1)) * width
                        var y = height - (history1[i] / maxValue) * height
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.stroke()
                }

                // linha 2
                if (history2.length > 1) {
                    ctx.strokeStyle = root.color2
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    for (var j = 0; j < history2.length; j++) {
                        var x2 = (j / (history2.length - 1)) * width
                        var y2 = height - (history2[j] / maxValue) * height
                        if (j === 0) ctx.moveTo(x2, y2)
                        else ctx.lineTo(x2, y2)
                    }
                    ctx.stroke()
                }
            }
        }

        Text {
            text: root.displayLabel1 !== "" ? root.displayLabel1 : root.label1
            color: root.color1
            font.pixelSize: 10
            font.bold: true
            style: Text.Outline
            styleColor: "black"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 3
            anchors.topMargin: 3
            anchors.right: parent.horizontalCenter
            elide: Text.ElideRight
            z: 1
        }

        Text {
            text: root.displayLabel2 !== "" ? root.displayLabel2 : root.label2
            color: root.color2
            font.pixelSize: 10
            font.bold: true
            style: Text.Outline
            styleColor: "black"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.left: parent.horizontalCenter
            anchors.rightMargin: 3
            anchors.topMargin: 3
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            z: 1
        }
    }
}
