import QtQuick
import QtQuick.Layouts
Item {
    id: compact
    required property var backend
    property bool notch: false
    property bool showBattery: true
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    onVisibleChanged: { if (!visible) hoverChanged(false); }
    signal activated()
    signal hoverChanged(bool hovered)
    signal filesDropped(var urls)
    implicitWidth: 240; implicitHeight: 42
    IslandSurface { anchors.fill: parent; notch: compact.notch }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
        Rectangle { implicitWidth: 7; implicitHeight: 7; radius: 4; color: compact.backend.playing ? "#b9a3ff" : "#555767" }
        Text { Layout.fillWidth: true; text: compact.backend.title || compact.clockText; color: "#f5f5fa"; font.pixelSize: 13; elide: Text.ElideRight; textFormat: Text.PlainText }
        Text { visible: compact.showBattery && compact.backend.hasBattery; text: (compact.backend.charging ? "+ " : "") + compact.backend.percent + "%"; color: "#a7e7b8"; font.pixelSize: 11 }
    }
    HoverHandler { onHoveredChanged: compact.hoverChanged(hovered) }
    TapHandler { onTapped: compact.activated() }
    DropArea { anchors.fill: parent; onDropped: drop => { if (drop.hasUrls) { compact.filesDropped(drop.urls); drop.acceptProposedAction(); } } }
    Keys.onReturnPressed: activated()
    Keys.onSpacePressed: activated()
    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Open Boring Island")
    Timer { interval: 1000; running: true; repeat: true; onTriggered: compact.clockText = Qt.formatTime(new Date(), "hh:mm") }
}
