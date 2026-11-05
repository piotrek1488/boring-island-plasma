import QtQuick
import QtQuick.Layouts
Item {
    id: compact
    readonly property alias visualItem: visual
    property string language: "en"
    Translations { id: strings; language: compact.language }
    required property var backend
    property string displayText: ""
    property color accentColor: "#b9a3ff"
    property bool drawSurface: true
    property bool connected: false
    property bool animateMedia: false
    property bool reduceMotion: false
    readonly property real textWidth: textMetrics.width + 64 * contentScale + (showBattery && backend.hasBattery ? 52 * contentScale : 0)
    TextMetrics { id: textMetrics; text: compact.displayText || compact.backend.title || compact.clockText; font.pixelSize: Math.round(13 * compact.contentScale) }
    property bool notch: false
    property bool showBattery: true
    property real compactScale: 1
    property real minimumTextScale: 0.5
    property bool expandedHeader: false
    property real edgeInset: expandedHeader ? 32 : 16
    property real batteryFontSize: expandedHeader ? 14 : 11
    property bool autoHeight: true
    property int compactHeight: 42
    readonly property real effectiveHeight: Math.max(0, Math.min(height, (autoHeight ? height : Math.max(16, Math.min(128, compactHeight))) * compactScale))
    readonly property real contentScale: Math.max(minimumTextScale, Math.min(2, effectiveHeight / 42))
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
        IslandSurface { anchors.fill: parent; notch: compact.notch; visible: compact.drawSurface; connected: compact.connected }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: compact.edgeInset * compact.contentScale; anchors.rightMargin: compact.edgeInset * compact.contentScale; spacing: 10 * compact.contentScale
            Rectangle { implicitWidth: 7 * compact.contentScale; implicitHeight: implicitWidth; radius: implicitWidth / 2; color: compact.accentColor
                SequentialAnimation on opacity { running: compact.animateMedia && compact.backend.playing && !compact.reduceMotion && compact.visible; loops: Animation.Infinite; NumberAnimation { to: 0.3; duration: 600 } NumberAnimation { to: 1; duration: 600 } } }
            Text { objectName: "compactTitle"; Layout.fillWidth: true; text: compact.displayText || compact.backend.title || compact.clockText; color: "#f5f5fa"; font.pixelSize: Math.round(13 * compact.contentScale); elide: Text.ElideRight; textFormat: Text.PlainText }
            Text { objectName: "compactBattery"; visible: compact.showBattery && compact.backend.hasBattery; text: (compact.backend.charging ? "+ " : "") + compact.backend.percent + "%"; color: "#a7e7b8"; font.pixelSize: Math.round(compact.batteryFontSize * compact.contentScale) }
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
