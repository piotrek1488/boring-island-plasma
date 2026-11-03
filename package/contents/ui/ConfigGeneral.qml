import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
Kirigami.FormLayout {
    id: config
    property string cfg_language: "en"
    readonly property string language: cfg_language
    Translations { id: strings; language: config.language }
    property alias cfg_shape: shape.currentIndex
    property alias cfg_hoverOpen: hover.checked
    property alias cfg_hoverDelay: delay.value
    property alias cfg_compactWidth: size.value
    property alias cfg_showBattery: battery.checked
    property alias cfg_reduceMotion: motion.checked
    ComboBox {
        id: languageChoice
        objectName: "languageChoice"
        Kirigami.FormData.label: strings.text("Language:")
        model: ["English", "Polski"]
        currentIndex: config.cfg_language === "pl" ? 1 : 0
        onActivated: index => config.cfg_language = index === 1 ? "pl" : "en"
    }
    ComboBox { id: shape; Kirigami.FormData.label: strings.text("Shape:"); model: [strings.text("Notch"), "Dynamic Island"] }
    SpinBox { id: size; Kirigami.FormData.label: strings.text("Compact width:"); from: 180; to: 400; stepSize: 10 }
    CheckBox { id: hover; text: strings.text("Expand on hover") }
    SpinBox { id: delay; Kirigami.FormData.label: strings.text("Hover delay (ms):"); from: 100; to: 1500; stepSize: 50 }
    CheckBox { id: battery; text: strings.text("Show battery status") }
    CheckBox { id: motion; text: strings.text("Reduce motion") }
    Label { text: strings.text("For an island at the top of the screen, place this widget in a centered top panel."); wrapMode: Text.WordWrap; LayoutMirroring.enabled: false }
}
