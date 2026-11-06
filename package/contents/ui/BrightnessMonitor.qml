pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models

Item {
    id: monitor
    visible: false
    property var model: null
    signal changed(int percent, string displayLabel)
    Instantiator {
        model: monitor.model
        delegate: QtObject {
            id: display
            required property int brightness
            required property int maxBrightness
            required property string label
            property bool ready: false
            property bool monitoring: monitor.enabled
            property int previousBrightness: 0
            property int previousMaximum: 0
            function seed() {
                previousBrightness = brightness;
                previousMaximum = maxBrightness;
                ready = true;
            }
            function refresh() {
                if (!ready) return;
                const changed = brightness !== previousBrightness;
                const sameRange = maxBrightness === previousMaximum;
                seed();
                // Initial values, hotplug and range changes are not user adjustments.
                if (monitor.enabled && changed && sameRange && maxBrightness > 0) {
                    monitor.changed(Math.round(100 * Math.max(0, Math.min(maxBrightness, brightness)) / maxBrightness), label);
                }
            }
            onBrightnessChanged: if (ready) Qt.callLater(refresh)
            onMaxBrightnessChanged: if (ready) Qt.callLater(refresh)
            onMonitoringChanged: if (ready) seed()
            Component.onCompleted: seed()
        }
    }
}
