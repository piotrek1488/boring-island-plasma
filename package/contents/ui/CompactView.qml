import QtQuick
import QtQuick.Layouts
Item {
    id: compact
    readonly property alias visualItem: visual
    property string language: "en"
    Translations { id: strings; language: compact.language }
    required property var backend
    property string displayText: ""
    property string alternateText: ""
    property bool cycleText: false
    property int cycleInterval: 4000
    property bool batteryOnly: false
    property var osd: null
    property color accentColor: "#b9a3ff"
    property bool drawSurface: true
    property bool connected: false
    property bool animateMedia: false
    property bool reduceMotion: false
    readonly property real unscaledHeight: autoHeight ? (panelItem ? panelItem.height : height) : Math.max(16, Math.min(128, compactHeight))
    readonly property real naturalScale: Math.max(0.5, Math.min(2, unscaledHeight / 42))
    readonly property real naturalWidth: Math.max(batteryOnly ? 0 : naturalMetrics.width, cycleText ? alternateMetrics.width : 0) + (96 + (expandedHeader ? 54 : 0) + (showBattery && backend.hasBattery ? batteryIndicator.implicitWidth / contentScale : 0)) * naturalScale
    TextMetrics { id: naturalMetrics; text: compact.displayText || compact.backend.title || compact.clockText; font.pixelSize: Math.round(13 * compact.naturalScale) }
    TextMetrics { id: alternateMetrics; text: compact.alternateText; font.pixelSize: Math.round(13 * compact.naturalScale) }
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
    signal closeRequested()
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
                const closePoint = closeButton.mapFromItem(visual, mouse.x, mouse.y);
                if ((!settingsButton.visible || !settingsButton.contains(point)) && (!closeButton.visible || !closeButton.contains(closePoint))) compact.activated();
            }
        }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: compact.horizontalPadding; anchors.rightMargin: compact.horizontalPadding; spacing: 10 * compact.contentScale
            Rectangle { visible: !compact.batteryOnly && compact.osd === null; implicitWidth: 7 * compact.contentScale; implicitHeight: implicitWidth; radius: implicitWidth / 2; color: compact.accentColor
                SequentialAnimation on opacity { running: compact.animateMedia && compact.backend.playing && !compact.reduceMotion && compact.visible; loops: Animation.Infinite; NumberAnimation { to: 0.3; duration: 600 } NumberAnimation { to: 1; duration: 600 } } }
            RotatingLabel {
                objectName: "compactTextViewport"
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: !compact.batteryOnly && compact.osd === null
                primaryText: compact.displayText || compact.backend.title || compact.clockText
                secondaryText: compact.alternateText; cycling: compact.cycleText
                interval: compact.cycleInterval; reduceMotion: compact.reduceMotion
                fontSize: 13 * compact.contentScale
            }
            Item { visible: compact.batteryOnly; Layout.fillWidth: true }
            RowLayout {
                objectName: "compactOsd"
                visible: compact.osd !== null
                Layout.fillWidth: true; spacing: 6 * compact.contentScale
                Text { text: compact.osd && compact.osd.kind === "brightness" ? "☀" : "♫"; color:"#f5f5fa"; font.pixelSize:Math.round(13*compact.contentScale) }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 4 * compact.contentScale; radius: height/2; color: "#34353f"
                    Rectangle { width: parent.width * (compact.osd ? compact.osd.value / compact.osd.maximum : 0); height:parent.height; radius:height/2; color:"#c4b5fd" }
                }
                Text { text: compact.osd ? Math.round(compact.osd.value)+"%" : ""; color:"#f5f5fa"; font.pixelSize:Math.round(11*compact.contentScale) }
                Accessible.role: Accessible.Indicator
                Accessible.name: (compact.osd && compact.osd.kind === "brightness" ? strings.text("Brightness") : strings.text("Volume")) + " " + (compact.osd ? Math.round(compact.osd.value)+"%" : "")
            }
            BatteryIndicator {
                id: batteryIndicator
                objectName: "compactBattery"
                visible: compact.showBattery && compact.backend.hasBattery && compact.osd === null
                language: compact.language; percent: compact.backend.percent
                status: compact.backend.batteryStatus || (compact.backend.charging ? "charging" : "discharging")
                percentPosition: compact.batteryPercentPosition
                scaleFactor: compact.contentScale; fontSize: compact.batteryFontSize * compact.contentScale
            }
            Item { visible: compact.batteryOnly; Layout.fillWidth: true }
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
            ActionButton {
                id: closeButton
                objectName: "closeButton"
                visible: compact.expandedHeader
                text: "×"; textSize: Math.max(9, 16 * compact.contentScale)
                implicitWidth: Math.max(16, 22 * compact.contentScale); implicitHeight: implicitWidth
                leftPadding: 3; rightPadding: 3
                Accessible.name: strings.text("Close")
                Accessible.description: strings.text("Close")
                onClicked: compact.closeRequested()
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
