.pragma library

// Kept in sync with KConfig by tests/test_settings_defaults.py. Shelf data is preserved.
var values = {
    "language": "en",
    "calendarMode": "kde",
    "calendarSources": "",
    "shape": 1,
    "hoverOpen": true,
    "hoverDelay": 250,
    "autoHeight": true,
    "compactScale": 100,
    "compactHeight": 42,
    "compactWidth": 320,
    "autoWidth": true,
    "compactMinimumWidth": 180,
    "expandedWidth": 600,
    "expandedHeight": 400,
    "expandedScale": 100,
    "notificationDuration": 4,
    "notificationPreviews": true,
    "pinnedMode": "auto",
    "monitorSystem": true,
    "monitorPackages": true,
    "monitorLlm": false,
    "showAudioDevice": true,
    "showBattery": true,
    "batteryPercentPosition": "right",
    "animationDuration": 400,
    "reduceMotion": false
};

function restore(target) {
    for (var name in values) target["cfg_" + name] = values[name];
}
