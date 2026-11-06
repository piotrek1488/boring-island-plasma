import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

Item {
    id: backend
    visible: false
    readonly property bool available: control.isBrightnessAvailable
    signal brightnessChanged(int percent, string displayLabel)
    // Observe the same model as KDE's brightness widget. Never call its setters.
    Brightness.ScreenBrightnessControl { id: control }
    BrightnessMonitor {
        model: control.displays
        onChanged: (percent, label) => backend.brightnessChanged(percent, label)
    }
}
