import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
Kirigami.FormLayout {
    id: config
    property string cfg_language: "en"
    readonly property string language: cfg_language
    Translations { id: strings; language: config.language }
    property alias cfg_compactScale: compactScale.value
    property alias cfg_autoWidth: autoWidth.checked
    property alias cfg_expandedWidth: expandedWidth.value
    property alias cfg_expandedHeight: expandedHeight.value
    property alias cfg_expandedScale: expandedScale.value
    property alias cfg_notificationDuration: notificationDuration.value
    property alias cfg_notificationPreviews: notificationPreviews.checked
    property alias cfg_monitorSystem: monitorSystem.checked
    property alias cfg_monitorPackages: monitorPackages.checked
    property alias cfg_monitorLlm: monitorLlm.checked
    property alias cfg_showAudioDevice: audioDevice.checked
    property string cfg_pinnedMode: "auto"
    property alias cfg_shape: shape.currentIndex
    property alias cfg_hoverOpen: hover.checked
    property alias cfg_hoverDelay: delay.value
    property alias cfg_autoHeight: autoSize.checked
    property alias cfg_compactHeight: heightSize.value
    property alias cfg_compactWidth: size.value
    property alias cfg_showBattery: battery.checked
    property string cfg_batteryPercentPosition: "right"
    property alias cfg_animationDuration: animationDuration.value
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
    SpinBox { id: size; Kirigami.FormData.label: strings.text("Compact width:"); from: 80; to: 1000; stepSize: 10; editable: true }
    CheckBox { id: autoWidth; text: strings.text("Fit width to content (compact width is the limit)") }
    SpinBox { id: expandedWidth; Kirigami.FormData.label: strings.text("Expanded width (px):"); from: 420; to: 1000; value: 520; editable: true }
    SpinBox { id: expandedHeight; Kirigami.FormData.label: strings.text("Expanded height (px):"); from: 320; to: 800; value: 390; editable: true }
    SpinBox { id: expandedScale; Kirigami.FormData.label: strings.text("Expanded scale (%):"); from: 60; to: 200; value: 100; stepSize: 5; editable: true }
    SpinBox { id: compactScale; objectName: "compactScaleSetting"; Kirigami.FormData.label: strings.text("Compact scale (%):"); from: 50; to: 200; value: 100; stepSize: 5; editable: true }
    CheckBox { id: autoSize; objectName: "autoHeightSetting"; text: strings.text("Fit height to panel") }
    SpinBox { id: heightSize; objectName: "compactHeightSetting"; Kirigami.FormData.label: strings.text("Compact height (px):"); from: 16; to: 128; value: 42; stepSize: 1; editable: true; onValueModified: autoSize.checked = false }
    Label { text: strings.text("Editing the height disables automatic fitting. Height cannot exceed the panel; increase the panel height to grow further. Compact scale also changes width, even at the height limit."); wrapMode: Text.WordWrap }
    CheckBox { id: hover; text: strings.text("Expand on hover") }
    SpinBox { id: delay; Kirigami.FormData.label: strings.text("Hover delay (ms):"); from: 100; to: 1500; stepSize: 50 }
    CheckBox { id: battery; text: strings.text("Show battery status") }
    CheckBox { id: notificationPreviews; text: strings.text("Show notification previews") }
    SpinBox { id: notificationDuration; objectName: "notificationDurationSetting"; Kirigami.FormData.label: strings.text("Notification preview (seconds):"); from: 1; to: 60; value: 4; editable: true }
    ComboBox {
        Kirigami.FormData.label: strings.text("Panel view:")
        model: [strings.text("Automatic"), strings.text("Clock"), strings.text("Media"), strings.text("System"), strings.text("Packages"), strings.text("Local AI"), strings.text("Notifications")]
        currentIndex: Math.max(0, ["auto", "clock", "media", "system", "packages", "llm", "notifications"].indexOf(config.cfg_pinnedMode))
        onActivated: index => config.cfg_pinnedMode = ["auto", "clock", "media", "system", "packages", "llm", "notifications"][index]
    }
    CheckBox { id: monitorSystem; text: strings.text("Monitor CPU, RAM and GPU") }
    CheckBox { id: monitorPackages; text: strings.text("Detect package operations") }
    CheckBox { id: monitorLlm; text: strings.text("Monitor Ollama and LM Studio") }
    CheckBox { id: audioDevice; text: strings.text("Show audio output device") }
    ComboBox {
        objectName: "batteryPercentPositionSetting"
        Kirigami.FormData.label: strings.text("Battery percentage:")
        model: [strings.text("Inside the icon"), strings.text("Left of the icon"), strings.text("Right of the icon"), strings.text("Hidden")]
        currentIndex: Math.max(0, ["inside", "left", "right", "hidden"].indexOf(config.cfg_batteryPercentPosition))
        onActivated: index => config.cfg_batteryPercentPosition = ["inside", "left", "right", "hidden"][index]
    }
    SpinBox { id: animationDuration; objectName: "animationDurationSetting"; Kirigami.FormData.label: strings.text("Animation duration (ms):"); from: 50; to: 1000; value: 280; stepSize: 10; editable: true }
    Label { text: strings.text("Lower values make opening and closing faster. Reduced motion disables animations."); wrapMode: Text.WordWrap }
    CheckBox { id: motion; text: strings.text("Reduce motion") }
    Label { text: strings.text("For an island at the top of the screen, place this widget in a centered top panel."); wrapMode: Text.WordWrap; LayoutMirroring.enabled: false }
}
