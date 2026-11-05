import QtQuick
import QtQuick.Controls
Button {
    id: button
    property bool accent: false
    property real textSize: 16
    property bool showTooltip: true
    implicitWidth: Math.max(42, contentItem.implicitWidth + leftPadding + rightPadding); implicitHeight: 38
    leftPadding: 12; rightPadding: 12
    hoverEnabled: true
    Accessible.name: text
    contentItem: Text {
        text: button.text; color: button.enabled ? (button.accent ? "#090a0e" : "#f4f4f8") : "#60616c"
        textFormat: Text.PlainText
        font.pixelSize: button.textSize; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 13
        color: button.accent ? "#c4b5fd" : (button.down ? "#41414f" : button.hovered ? "#30313d" : "#1b1c24")
        border.width: button.activeFocus ? 2 : 0; border.color: "#c4b5fd"
    }
    ToolTip.visible: showTooltip && hovered && ToolTip.text.length > 0
    ToolTip.delay: 600
    ToolTip.text: Accessible.description
}
