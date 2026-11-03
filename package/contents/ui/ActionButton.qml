import QtQuick
import QtQuick.Controls
Button {
    id: button
    property bool accent: false
    implicitWidth: 42; implicitHeight: 38
    hoverEnabled: true
    Accessible.name: text
    contentItem: Text {
        text: button.text; color: button.enabled ? (button.accent ? "#090a0e" : "#f4f4f8") : "#60616c"
        font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 13
        color: button.accent ? "#c4b5fd" : (button.down ? "#41414f" : button.hovered ? "#30313d" : "#1b1c24")
        border.width: button.activeFocus ? 2 : 0; border.color: "#c4b5fd"
    }
    ToolTip.visible: hovered
    ToolTip.text: Accessible.description
}
