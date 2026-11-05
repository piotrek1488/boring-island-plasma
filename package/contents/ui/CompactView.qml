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
    readonly property real unscaledHeight: autoHeight ? (panelItem ? panelItem.height : height) : Math.max(16, Math.min(128, compactHeight))
    readonly property real naturalScale: Math.max(0.5, Math.min(2, unscaledHeight / 42))
    readonly property real naturalWidth: naturalMetrics.width + (96 + (expandedHeader ? 22 : 0) + (showBattery && backend.hasBattery ? batteryIndicator.implicitWidth / contentScale : 0)) * naturalScale
    TextMetrics { id: naturalMetrics; text: compact.displayText || compact.backend.title || compact.clockText; font.pixelSize: Math.round(13 * compact.naturalScale) }
    readonly property real textWidth: textMetrics.width + 86 * contentScale + (showBattery && backend.hasBattery ? batteryIndicator.implicitWidth : 0)
    TextMetrics { id: textMetrics; text: compact.displayText || compact.backend.title || compact.clockText; font.pixelSize: Math.round(13 * compact.contentScale) }
    // Paint in the panel content item so applet padding/clipping cannot crop the notch.
    property Item panelItem: null
    PanelAnchor { id: panelAnchor; source: compact; targetItem: compact.panelItem }
    property bool notch: false
    property bool showBattery: true
    property string batteryPercentPosition: "right"
    property bool configureEnabled: true
    signal configureRequested()
    property real compactScale: 1
    property real minimumTextScale: 0.5
    property bool expandedHeader: false
    property real edgeInset: expandedHeader ? 32 : 24
    readonly property real horizontalPadding: expandedHeader ? edgeInset * contentScale : Math.max(notch ? 28 : 22, edgeInset * contentScale)
    property real batteryFontSize: expandedHeader ? 14 : 11
    property bool autoHeight: true
    property int compactHeight: 42
    readonly property real effectiveHeight: Math.max(0, unscaledHeight * compactScale)
    readonly property real contentScale: Math.max(minimumTextScale, Math.min(2, effectiveHeight / 42))
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    onVisibleChanged: { if (!visible) hoverChanged(false); }
    signal activated()
    signal keyboardActivated()
    signal hoverChanged(bool hovered)
    signal filesDropped(var urls)
    implicitWidth: 240; implicitHeight: (autoHeight ? 42 : Math.max(16, Math.min(128, compactHeight))) * compactScale
    Item {
        id: visual
        objectName: "compactVisual"
        parent: compact.panelItem || compact
        visible: compact.visible
        enabled: compact.enabled
        opacity: compact.panelItem ? compact.opacity : 1
        x: panelAnchor.origin.x
        width: compact.width
        height: compact.effectiveHeight
        y: compact.notch ? 0 : panelAnchor.origin.y + (compact.height - height) / 2
        IslandSurface { anchors.fill: parent; notch: compact.notch; visible: compact.drawSurface; connected: compact.connected }
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => {
                const point = settingsButton.mapFromItem(visual, mouse.x, mouse.y);
                if (!settingsButton.visible || !settingsButton.contains(point)) compact.activated();
            }
        }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: compact.horizontalPadding; anchors.rightMargin: compact.horizontalPadding; spacing: 10 * compact.contentScale
            Rectangle { implicitWidth: 7 * compact.contentScale; implicitHeight: implicitWidth; radius: implicitWidth / 2; color: compact.accentColor
                SequentialAnimation on opacity { running: compact.animateMedia && compact.backend.playing && !compact.reduceMotion && compact.visible; loops: Animation.Infinite; NumberAnimation { to: 0.3; duration: 600 } NumberAnimation { to: 1; duration: 600 } } }
            Text { objectName: "compactTitle"; Layout.fillWidth: true; text: compact.displayText || compact.backend.title || compact.clockText; color: "#f5f5fa"; font.pixelSize: Math.round(13 * compact.contentScale); elide: Text.ElideRight; textFormat: Text.PlainText }
            BatteryIndicator {
                id: batteryIndicator
                objectName: "compactBattery"
                visible: compact.showBattery && compact.backend.hasBattery
                language: compact.language; percent: compact.backend.percent
                status: compact.backend.batteryStatus || (compact.backend.charging ? "charging" : "discharging")
                percentPosition: compact.batteryPercentPosition
                scaleFactor: compact.contentScale; fontSize: compact.batteryFontSize * compact.contentScale
            }
            ActionButton {
                id: settingsButton
                objectName: "settingsButton"
                visible: compact.expandedHeader
                text: "⚙"; textSize: Math.max(9, 16 * compact.contentScale)
                implicitWidth: Math.max(16, 22 * compact.contentScale); implicitHeight: implicitWidth
                leftPadding: 3; rightPadding: 3
                enabled: compact.configureEnabled
                Accessible.name: strings.text("Configure Boring Island")
                Accessible.description: strings.text("Configure Boring Island")
                onClicked: compact.configureRequested()
            }
        }
        HoverHandler { onHoveredChanged: compact.hoverChanged(hovered) }
        DropArea { anchors.fill: parent; onDropped: drop => { if (drop.hasUrls) { compact.filesDropped(drop.urls); drop.acceptProposedAction(); } } }
    }
    Keys.onReturnPressed: keyboardActivated()
    Keys.onSpacePressed: keyboardActivated()
    Accessible.role: Accessible.Button
    Accessible.name: strings.text("Open Boring Island")
    Timer { interval: 1000; running: true; repeat: true; onTriggered: compact.clockText = Qt.formatTime(new Date(), "hh:mm") }
}
