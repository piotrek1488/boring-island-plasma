import QtQuick
import QtQuick.Layouts
Item {
    id: compact
    property string language: "en"
    Translations { id: strings; language: compact.language }
    required property var backend
    property bool notch: false
    property bool showBattery: true
    property bool autoHeight: true
    property int compactHeight: 42
    readonly property real effectiveHeight: Math.max(0, Math.min(height, autoHeight ? height : Math.max(16, Math.min(128, compactHeight))))
    readonly property real contentScale: Math.max(0.5, Math.min(2, effectiveHeight / 42))
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    onVisibleChanged: { if (!visible) hoverChanged(false); }
    signal activated()
    signal hoverChanged(bool hovered)
    signal filesDropped(var urls)
    implicitWidth: 240; implicitHeight: autoHeight ? 42 : Math.max(16, Math.min(128, compactHeight))
    Item {
        id: visual
        objectName: "compactVisual"
        width: compact.width
        height: compact.effectiveHeight
        y: compact.notch ? 0 : (compact.height - height) / 2
        IslandSurface { anchors.fill: parent; notch: compact.notch }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16 * compact.contentScale; anchors.rightMargin: 16 * compact.contentScale; spacing: 10 * compact.contentScale
            Rectangle { implicitWidth: 7 * compact.contentScale; implicitHeight: implicitWidth; radius: implicitWidth / 2; color: compact.backend.playing ? "#b9a3ff" : "#555767" }
            Text { Layout.fillWidth: true; text: compact.backend.title || compact.clockText; color: "#f5f5fa"; font.pixelSize: Math.round(13 * compact.contentScale); elide: Text.ElideRight; textFormat: Text.PlainText }
            Text { visible: compact.showBattery && compact.backend.hasBattery; text: (compact.backend.charging ? "+ " : "") + compact.backend.percent + "%"; color: "#a7e7b8"; font.pixelSize: Math.round(11 * compact.contentScale) }
        }
        HoverHandler { onHoveredChanged: compact.hoverChanged(hovered) }
        TapHandler { onTapped: compact.activated() }
        DropArea { anchors.fill: parent; onDropped: drop => { if (drop.hasUrls) { compact.filesDropped(drop.urls); drop.acceptProposedAction(); } } }
    }
    Keys.onReturnPressed: activated()
    Keys.onSpacePressed: activated()
    Accessible.role: Accessible.Button
    Accessible.name: strings.text("Open Boring Island")
    Timer { interval: 1000; running: true; repeat: true; onTriggered: compact.clockText = Qt.formatTime(new Date(), "hh:mm") }
}
