import QtQuick
Item {
    id: surface
    property bool notch: false
    property bool connected: false
    property color fill: "#090a0e"
    Rectangle {
        anchors.fill: parent
        color: surface.fill
        radius: surface.notch ? 22 : Math.min(height / 2, 30)
        border.color: "#272831"
        border.width: surface.notch || surface.connected ? 0 : 1
    }
    Rectangle {
        visible: surface.notch || surface.connected
        width: parent.width; height: Math.min(22, parent.height / 2)
        color: surface.fill
    }
}
