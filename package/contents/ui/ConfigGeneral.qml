import QtQuick
import QtQuick.Controls
import "../code/SettingsDefaults.js" as Defaults
import org.kde.kirigami as Kirigami
Kirigami.FormLayout {
    id: config
    property string cfg_idleView: "clock"
    property alias cfg_mediaCycleSeconds: mediaCycleSeconds.value
    property alias cfg_showOsd: showOsd.checked
    property alias cfg_osdDuration: osdDuration.value
    property alias cfg_remindersEnabled: reminders.checked
    property alias cfg_reminderLeadMinutes: reminderLead.value
    property string cfg_calendarMode: "kde"
    property alias cfg_calendarSources: calendarSources.text
    property string cfg_language: "en"
    readonly property string language: cfg_language
    Translations { id: strings; language: config.language }
    property alias cfg_compactScale: compactScale.value
    property alias cfg_compactMinimumWidth: minimumWidth.value
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
    property string cfg_animationStyle: "smooth"
    property alias cfg_animationDuration: animationDuration.value
    property alias cfg_reduceMotion: motion.checked
    function restoreDefaults() { Defaults.restore(config); }
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
    SpinBox { id: minimumWidth; objectName: "compactMinimumWidthSetting"; Kirigami.FormData.label: strings.text("Minimum compact width (px):"); from: 80; to: 1000; value: 180; stepSize: 10; editable: true; enabled: autoWidth.checked }
    SpinBox { id: expandedWidth; Kirigami.FormData.label: strings.text("Expanded width (px):"); from: 420; to: 1000; value: 600; editable: true }
    SpinBox { id: expandedHeight; Kirigami.FormData.label: strings.text("Expanded height (px):"); from: 320; to: 800; value: 400; editable: true }
    SpinBox { id: expandedScale; Kirigami.FormData.label: strings.text("Expanded scale (%):"); from: 60; to: 200; value: 100; stepSize: 5; editable: true }
    SpinBox { id: compactScale; objectName: "compactScaleSetting"; Kirigami.FormData.label: strings.text("Compact scale (%):"); from: 50; to: 200; value: 100; stepSize: 5; editable: true }
    CheckBox { id: autoSize; objectName: "autoHeightSetting"; text: strings.text("Fit height to panel") }
    SpinBox { id: heightSize; objectName: "compactHeightSetting"; Kirigami.FormData.label: strings.text("Compact height (px):"); from: 16; to: 128; value: 42; stepSize: 1; editable: true; onValueModified: autoSize.checked = false }
    Label { text: strings.text("Manual height and scale apply to the visible shape. Use a non-floating top panel to attach a notch to the screen edge."); wrapMode: Text.WordWrap }
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
    ComboBox {
        objectName: "idleViewSetting"
        Kirigami.FormData.label: strings.text("Idle view:")
        model: [strings.text("Clock and battery"), strings.text("Date, clock and battery"), strings.text("Battery only")]
        currentIndex: Math.max(0,["clock","dateClock","battery"].indexOf(config.cfg_idleView))
        onActivated: index => config.cfg_idleView=["clock","dateClock","battery"][index]
    }
    Label { text: strings.text("Live activity takes priority over the preferred panel view. Empty notifications fall back to the idle view."); wrapMode: Text.WordWrap }
    SpinBox { id: mediaCycleSeconds; Kirigami.FormData.label: strings.text("Media text rotation (seconds):"); from:1; to:15; value:4; editable:true }
    CheckBox { id: showOsd; text: strings.text("Show volume and brightness in the compact widget") }
    Label { visible:showOsd.checked; text:strings.text("These indicators appear alongside KDE system indicators."); wrapMode:Text.WordWrap }
    SpinBox { id: osdDuration; Kirigami.FormData.label: strings.text("Volume/brightness display (seconds):"); from:1; to:15; value:2; enabled:showOsd.checked; editable:true }
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
    ComboBox {
        objectName: "animationStyleSetting"
        Kirigami.FormData.label: strings.text("Animation style:")
        model: [strings.text("Smooth"), strings.text("Dynamic Island — spring")]
        currentIndex: config.cfg_animationStyle === "spring" ? 1 : 0
        enabled: !motion.checked
        onActivated: index => config.cfg_animationStyle = index === 1 ? "spring" : "smooth"
    }
    SpinBox { id: animationDuration; objectName: "animationDurationSetting"; Kirigami.FormData.label: strings.text("Animation duration (ms):"); from: 50; to: 1000; value: 400; stepSize: 10; editable: true }
    Label { text: strings.text("Lower values make opening faster. Closing uses 70% of that duration, limited to 100–220 ms. Reduced motion disables animations."); wrapMode: Text.WordWrap }
    CheckBox { id: motion; text: strings.text("Reduce motion") }
    Label { text: strings.text("For an island at the top of the screen, place this widget in a centered top panel."); wrapMode: Text.WordWrap; LayoutMirroring.enabled: false }
    ComboBox {
        Kirigami.FormData.label: strings.text("Calendar source:")
        model: [strings.text("KDE / Akonadi"), strings.text("ICS subscriptions / files")]
        currentIndex: config.cfg_calendarMode === "ics" ? 1 : 0
        onActivated: index => config.cfg_calendarMode = index === 1 ? "ics" : "kde"
    }
    CheckBox { id: reminders; text: strings.text("Calendar reminders before events and at their start") }
    SpinBox { id: reminderLead; Kirigami.FormData.label: strings.text("Reminder lead time (minutes):"); from:0; to:120; value:15; enabled:reminders.checked; editable:true }
    Label { text: strings.text("Reminders work with the calendar tab closed. All-day events are excluded. Zero minutes enables start reminders only."); wrapMode:Text.WordWrap }
    TextArea {
        id: calendarSources
        objectName: "calendarSourcesSetting"
        Kirigami.FormData.label: strings.text("ICS addresses or file paths:")
        visible: config.cfg_calendarMode === "ics"
        implicitWidth: 320; implicitHeight: 90
        wrapMode: TextEdit.WrapAnywhere
        placeholderText: "https://…/calendar.ics"
        selectByMouse: true
    }
    Label {
        visible: config.cfg_calendarMode === "ics"
        text: strings.text("One subscription address or local ICS file per line. Read-only; refreshes every five minutes. Google: secret iCal address. Outlook: published ICS link.")
        wrapMode: Text.WordWrap
    }
    Label {
        visible: config.cfg_calendarMode === "ics"
        text: strings.text("Install calendar support using the setup instructions. Subscription addresses can grant access to calendar data; keep them private.")
        wrapMode: Text.WordWrap
    }
    Button {
        visible: config.cfg_calendarMode === "ics"
        text: strings.text("Calendar setup instructions")
        onClicked: Qt.openUrlExternally("https://github.com/piotrek1488/boring-island-plasma/blob/main/README.md#google-and-outlook-calendars-without-akonadi")
    }
    Label {
        text: strings.text("Use Apply or OK to save the reset. Shelf shortcuts are kept.")
        wrapMode: Text.WordWrap
    }
    Button {
        objectName: "resetDefaultsButton"
        text: strings.text("Restore default settings")
        icon.name: "edit-undo"
        onClicked: config.restoreDefaults()
    }

}
