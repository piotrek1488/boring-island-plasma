import QtQuick
import org.kde.notification as KNotify
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: bridge
    visible: false
    property string language: "en"
    signal reminderActivated()
    property bool osdEnabled: true
    signal progressReceived(string icon, real value, real maximum, string description)
    signal textReceived(string icon, string description)
    signal delivered(string key)
    readonly property bool brightnessAvailable: brightnessLoader.item ? brightnessLoader.item.available : false
    Loader {
        id: brightnessLoader
        active: bridge.osdEnabled
        source: "BrightnessBackend.qml"
    }
    Connections {
        target: brightnessLoader.item
        function onBrightnessChanged(percent, displayLabel) {
            if (bridge.osdEnabled) bridge.progressReceived("video-display-brightness", percent, 100, displayLabel);
        }
    }
    DBus.SignalWatcher {
        enabled: bridge.osdEnabled
        busType: DBus.BusType.Session
        service: "org.kde.plasmashell"
        path: "/org/kde/osdService"
        iface: "org.kde.osdService"
        function dbusosdProgress(icon, value, maximum, description) { bridge.progressReceived(String(icon),Number(value),Number(maximum),String(description)); }
        function dbusosdText(icon, description) { bridge.textReceived(String(icon),String(description)); }
    }
    Translations { id: strings; language:bridge.language }
    // Reminders are sent with KNotification, never DBus.SessionBus.asyncCall(Notify).
    // plasmashell hosts org.freedesktop.Notifications itself, so asyncCall was a
    // local call whose reply crashed the libdbusplugin decoder (Plasma 6.6.6).
    // KNotification sends through C++ QtDBus, and because plasmashell stays the
    // sender, the server keeps the default action. See docs/issues/0001-*.md.
    Component {
        id: reminderComponent
        KNotify.Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "view-calendar"
            // autoDelete (default) frees the object once the notification closes.
            defaultAction: KNotify.NotificationAction {
                label: strings.text("Open calendar")
                onActivated: bridge.reminderActivated()
            }
        }
    }
    function notify(key, title, body) {
        const safeBody = String(body).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
        const note = reminderComponent.createObject(bridge, {title: String(title), text: safeBody});
        if (!note) return;
        note.sendEvent();
        bridge.delivered(key);
    }
}
