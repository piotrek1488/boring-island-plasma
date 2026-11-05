import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: battery
    property string language: "en"
    property int percent: 0
    property string status: "discharging"
    property string percentPosition: "right"
    property real scaleFactor: 1
    property real fontSize: 11 * scaleFactor
    readonly property string position: ["inside", "left", "right", "hidden"].indexOf(percentPosition) >= 0 ? percentPosition : "right"
    readonly property int level: Math.max(0, Math.min(100, percent))
    readonly property color levelColor: level <= 20 ? "#ff9494" : "#a7e7b8"
    readonly property string statusText: status === "charging" ? strings.text("Charging") : status === "full" ? strings.text("Fully charged") : status === "plugged" ? strings.text("Plugged in, not charging") : strings.text("Discharging")
    readonly property bool hasStatusMark: status === "charging"
    spacing: 5 * scaleFactor
    Translations { id: strings; language: battery.language }
    Accessible.role: Accessible.Indicator
    Accessible.name: strings.text("Battery") + " · " + level + "% · " + statusText
    ToolTip.visible: hover.hovered
    ToolTip.delay: 600
    ToolTip.text: Accessible.name
    HoverHandler { id: hover }
    Text {
        objectName: "batteryPercentLeft"
        visible: battery.position === "left"
        text: battery.level + "%"; color: battery.levelColor
        font.pixelSize: Math.round(battery.fontSize)
    }
    Canvas {
        id: chargingMark
        objectName: "batteryStatusMark"
        visible: battery.hasStatusMark
        Layout.preferredWidth: 12 * battery.scaleFactor
        Layout.preferredHeight: 16 * battery.scaleFactor
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset(); ctx.scale(width / 12, height / 16);
            ctx.fillStyle = battery.levelColor;
            ctx.beginPath();
            ctx.moveTo(7,1); ctx.lineTo(1,9); ctx.lineTo(5,9);
            ctx.lineTo(3,15); ctx.lineTo(11,6); ctx.lineTo(7,6);
            ctx.closePath(); ctx.fill();
        }
        onWidthChanged: requestPaint()
        Connections { target: battery; function onLevelColorChanged() { chargingMark.requestPaint(); } }
    }
    Item {
        id: icon
        objectName: "batteryIcon"
        readonly property real bodyWidth: (battery.position === "inside" ? 43 : 26) * battery.scaleFactor
        implicitWidth: bodyWidth + 3 * battery.scaleFactor
        implicitHeight: 17 * battery.scaleFactor
        Rectangle {
            width: icon.bodyWidth; height: parent.height
            radius: 3 * battery.scaleFactor
            color: "transparent"; border.color: battery.levelColor
            border.width: Math.max(1, 1.3 * battery.scaleFactor)
            Rectangle {
                x: 3 * battery.scaleFactor; y: 3 * battery.scaleFactor
                width: Math.max(0, (parent.width - 6 * battery.scaleFactor) * battery.level / 100)
                height: Math.max(0, parent.height - 6 * battery.scaleFactor)
                radius: battery.scaleFactor
                color: battery.levelColor
                opacity: battery.position === "inside" ? 0.3 : 0.65
            }
            Text {
                objectName: "batteryPercentInside"
                anchors.centerIn: parent
                visible: battery.position === "inside"
                text: battery.level + "%"; color: "#f5f5fa"
                font.pixelSize: Math.round(11 * battery.scaleFactor)
                font.bold: true
            }
        }
        Rectangle {
            x: icon.bodyWidth; anchors.verticalCenter: parent.verticalCenter
            width: 3 * battery.scaleFactor; height: 7 * battery.scaleFactor
            radius: battery.scaleFactor; color: battery.levelColor
        }

    }
    Text {
        objectName: "batteryPercentRight"
        visible: battery.position === "right"
        text: battery.level + "%"; color: battery.levelColor
        font.pixelSize: Math.round(battery.fontSize)
    }
}
