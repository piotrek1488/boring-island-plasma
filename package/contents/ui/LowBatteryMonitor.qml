import QtQuick

Item {
    id: monitor
    visible: false
    property bool hasBattery: false
    property int percent: 100
    property bool powered: false
    property int duration: 4000
    property bool suspended: false
    property bool active: false
    property bool warned: false
    signal warning()
    function dismiss() { active = false; expiry.stop(); }
    function update() {
        if (!hasBattery || powered || percent > 20) {
            warned = false;
            dismiss();
        } else if (!warned && percent >= 0) {
            warned = true;
            active = true;
            if (!suspended) expiry.restart();
            warning();
        }
    }
    // Coalesce BatteryControlModel's state/percentage updates during startup.
    onSuspendedChanged: { if (suspended) expiry.stop(); else if (active) expiry.restart(); }
    onHasBatteryChanged: Qt.callLater(update)
    onPercentChanged: Qt.callLater(update)
    onPoweredChanged: Qt.callLater(update)
    Component.onCompleted: Qt.callLater(update)
    Timer { id: expiry; interval: Math.max(1, monitor.duration); onTriggered: monitor.active = false }
}
