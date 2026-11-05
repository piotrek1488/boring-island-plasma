import QtQuick

Item {
    id: state
    visible: false
    property int duration: 2000
    property var current: null
    readonly property bool active: current !== null
    function dismiss() { timeout.stop(); current = null; }
    function progress(icon, value, maximum, description) {
        if (!enabled) return;
        const kind = icon.indexOf("audio-volume") === 0 ? "volume" : icon.indexOf("video-display-brightness") === 0 ? "brightness" : "";
        if (!kind || !isFinite(value) || !isFinite(maximum) || maximum <= 0) return;
        current = {kind:kind, value:Math.max(0, Math.min(maximum, value)), maximum:maximum, description:description || ""};
        timeout.restart();
    }
    function text(icon, description) {
        if (icon.indexOf("audio-volume-muted") === 0) progress(icon,0,100,description);
    }
    onEnabledChanged: if (!enabled) dismiss()
    Timer { id: timeout; interval: Math.max(100, state.duration); onTriggered: state.current = null }
}
