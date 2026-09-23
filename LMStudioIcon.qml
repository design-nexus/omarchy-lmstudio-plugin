import QtQuick
import qs.Commons
import qs.Ui

Item {
    id: root

    property real iconSize: Style.font.icon
    property color color: Color.foreground
    property color badgeColor: Color.urgent
    property color activeModelColor: "#38bdf8"
    property bool running: false
    property int modelCount: 0
    property bool warning: false
    property bool crossed: false

    width: iconSize
    height: iconSize
    implicitWidth: iconSize
    implicitHeight: iconSize

    readonly property real dotSize: Math.max(2, root.iconSize * 0.18)
    readonly property real spacing: Math.max(3, root.iconSize * 0.22)
    readonly property real startX: (root.iconSize - (root.dotSize * 3 + root.spacing * 2)) / 2
    readonly property real startY: (root.iconSize - (root.dotSize * 3 + root.spacing * 2)) / 2
    readonly property bool hasActiveModel: root.running && root.modelCount > 0

    // Neural network: 3x3 grid of neurons with connections
    // Draw connections first (lines between dots)
    Canvas {
        id: connections
        anchors.fill: parent
        visible: root.running

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.35)
            ctx.lineWidth = Math.max(1, root.iconSize * 0.05)
            ctx.lineCap = "round"

            var dots = []
            for (var row = 0; row < 3; row++) {
                for (var col = 0; col < 3; col++) {
                    var x = root.startX + col * (root.dotSize + root.spacing) + root.dotSize / 2
                    var y = root.startY + row * (root.dotSize + root.spacing) + root.dotSize / 2
                    dots.push({ x: x, y: y, row: row, col: col })
                }
            }

            // Connect each neuron to its right and bottom neighbors
            for (var i = 0; i < dots.length; i++) {
                var a = dots[i]
                // Right neighbor
                if (a.col < 2) {
                    var b = dots[i + 1]
                    ctx.beginPath()
                    ctx.moveTo(a.x, a.y)
                    ctx.lineTo(b.x, b.y)
                    ctx.stroke()
                }
                // Bottom neighbor
                if (a.row < 2) {
                    var b = dots[i + 3]
                    ctx.beginPath()
                    ctx.moveTo(a.x, a.y)
                    ctx.lineTo(b.x, b.y)
                    ctx.stroke()
                }
                // Diagonal bottom-right
                if (a.col < 2 && a.row < 2) {
                    var b = dots[i + 4]
                    ctx.beginPath()
                    ctx.moveTo(a.x, a.y)
                    ctx.lineTo(b.x, b.y)
                    ctx.stroke()
                }
                // Diagonal bottom-left
                if (a.col > 0 && a.row < 2) {
                    var b = dots[i + 2]
                    ctx.beginPath()
                    ctx.moveTo(a.x, a.y)
                    ctx.lineTo(b.x, b.y)
                    ctx.stroke()
                }
            }
        }
    }

    // Glowing halo for center neuron when a model is running
    Item {
        anchors.centerIn: parent
        visible: root.hasActiveModel
        width: root.dotSize
        height: root.dotSize

        // Outer glow layer with gentle pulse
        Rectangle {
            anchors.centerIn: parent
            width: root.dotSize * 2.8
            height: width
            radius: width / 2
            color: root.activeModelColor
            opacity: 0.25

            SequentialAnimation on opacity {
                running: root.hasActiveModel
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.15; duration: 1200; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale {
                running: root.hasActiveModel
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.95; duration: 1200; easing.type: Easing.InOutSine }
            }
        }

        // Mid glow layer
        Rectangle {
            anchors.centerIn: parent
            width: root.dotSize * 1.9
            height: width
            radius: width / 2
            color: root.activeModelColor
            opacity: 0.5

            SequentialAnimation on opacity {
                running: root.hasActiveModel
                loops: Animation.Infinite
                NumberAnimation { to: 0.75; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.35; duration: 1200; easing.type: Easing.InOutSine }
            }
        }
    }

    // Neurons (dots)
    Repeater {
        model: 9
        delegate: Rectangle {
            readonly property bool isCenter: index === 4
            readonly property bool isModelActive: isCenter && root.hasActiveModel

            x: root.startX + (index % 3) * (root.dotSize + root.spacing)
            y: root.startY + Math.floor(index / 3) * (root.dotSize + root.spacing)
            width: isModelActive ? root.dotSize * 1.3 : root.dotSize
            height: width
            radius: width / 2
            color: isModelActive ? root.activeModelColor : (root.running ? root.color : Qt.darker(root.color, 2.5))
            opacity: isModelActive ? 1.0 : (root.running ? 1.0 : 0.45)

            Behavior on width { NumberAnimation { duration: 150 } }
            Behavior on height { NumberAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // Warning badge (bottom-right)
    BorderSurface {
        visible: root.warning
        width: Math.max(7, parent.width * 0.42)
        height: width
        radius: width / 2
        color: root.badgeColor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        borderSpec: Border.flat(Color.popups.background, 1)

        Text {
            anchors.centerIn: parent
            text: "!"
            color: Color.background
            font.family: Style.font.family
            font.pixelSize: Math.max(6, parent.height * 0.72)
            font.bold: true
        }
    }

    // Stopped overlay (diagonal line through icon) - shown when crossed=true (installed but stopped)
    Rectangle {
        visible: root.crossed
        anchors.centerIn: parent
        width: parent.width * 1.3
        height: Math.max(2, parent.height * 0.12)
        radius: height / 2
        color: Qt.darker(root.color, 1.5)
        rotation: -45
        opacity: 0.7
    }
}