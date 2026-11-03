import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
Kirigami.FormLayout {
    id: config
    property alias cfg_shape: shape.currentIndex
    property alias cfg_hoverOpen: hover.checked
    property alias cfg_hoverDelay: delay.value
    property alias cfg_compactWidth: size.value
    property alias cfg_showBattery: battery.checked
    property alias cfg_reduceMotion: motion.checked
    ComboBox { id: shape; Kirigami.FormData.label: qsTr("Shape:"); model: [qsTr("Notch"), "Dynamic Island"] }
    SpinBox { id: size; Kirigami.FormData.label: qsTr("Compact width:"); from: 180; to: 400; stepSize: 10 }
    CheckBox { id: hover; text: qsTr("Expand on hover") }
    SpinBox { id: delay; Kirigami.FormData.label: qsTr("Hover delay (ms):"); from: 100; to: 1500; stepSize: 50 }
    CheckBox { id: battery; text: qsTr("Show battery status") }
    CheckBox { id: motion; text: qsTr("Reduce motion") }
    Label { text: qsTr("For an island at the top of the screen, place this widget in a centered top panel."); wrapMode: Text.WordWrap; LayoutMirroring.enabled: false }
}
