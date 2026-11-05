import QtQuick
Item {
    id: surface
    property bool notch: false
    property bool connected: false
    property color fill: "#090a0e"
    readonly property real shoulder: notch ? Math.min(8, height / 4, width / 8) : 0
    Rectangle {
        x: surface.shoulder; width: parent.width - 2 * x; height: parent.height
        color: surface.fill
        radius: surface.notch ? Math.min(22, height / 2) : Math.min(height / 2, 30)
        border.color: "#272831"
        border.width: surface.notch || surface.connected ? 0 : 1
    }
    Rectangle {
        visible: surface.notch || surface.connected
        x: surface.shoulder; width: parent.width - 2 * x; height: Math.min(22, parent.height / 2)
        color: surface.fill
    }
    // Only the small shoulders need textures; the animated body stays a rectangle.
    Repeater {
        model: surface.notch ? 2 : 0
        Canvas {
            id: corner
            required property int index
            width: surface.shoulder; height: width
            x: index === 0 ? 0 : surface.width - width
            transform: Scale { origin.x: surface.shoulder / 2; xScale: corner.index === 0 ? 1 : -1 }
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset(); ctx.fillStyle = surface.fill;
                ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(width, 0);
                ctx.lineTo(width, height); ctx.quadraticCurveTo(width, 0, 0, 0);
                ctx.closePath(); ctx.fill();
            }
            onWidthChanged: requestPaint()
            Connections { target: surface; function onFillChanged() { corner.requestPaint(); } }
        }
    }
}
