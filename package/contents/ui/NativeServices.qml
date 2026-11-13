import QtQuick
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: bridge
    visible: false
    property string language: "en"
    property var calendarNotifications: ({})
    signal reminderActivated()
    property bool osdEnabled: true
    // The notification server (org.freedesktop.Notifications) is hosted by
    // plasmashell itself. While the shell is still starting the name is not
    // owned yet, and asyncCall()'s reply decoder in libdbusplugin.so crashes
    // the whole process on the degenerate early reply. Gate Notify on the
    // server being ready and queue anything requested before then.
    property bool notificationsReady: false
    property var pendingNotifications: []
    onNotificationsReadyChanged: if (notificationsReady) flushPending()
    signal progressReceived(string icon, real value, real maximum, string description)
    signal textReceived(string icon, string description)
    signal delivered(string key, string notificationId)
    signal failed(string key)
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
    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: "org.freedesktop.Notifications"
        path: "/org/freedesktop/Notifications"
        iface: "org.freedesktop.Notifications"
        function dbusActionInvoked(id, action) {
            if (String(action)==="default" && bridge.calendarNotifications[String(id)]) bridge.reminderActivated();
        }
        function dbusNotificationClosed(id, reason) { delete bridge.calendarNotifications[String(id)]; }
    }
    Translations { id: strings; language:bridge.language }
    function notify(key, title, body) {
        // Never call asyncCall before the server owns the name: decoding its
        // early reply segfaults plasmashell. Queue and flush once it is ready.
        if (!bridge.notificationsReady) {
            bridge.pendingNotifications.push({key: String(key), title: String(title), body: String(body)});
            return;
        }
        bridge.deliver(key, title, body);
    }
    function deliver(key, title, body) {
        const safeBody = String(body).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
        DBus.SessionBus.asyncCall({service:"org.freedesktop.Notifications", path:"/org/freedesktop/Notifications",
            iface:"org.freedesktop.Notifications", member:"Notify", signature:"(susssasa{sv}i)",
            arguments:["Boring Island",new DBus.uint32(0),"view-calendar",String(title),safeBody,["default",strings.text("Open calendar")],{},-1]},
            reply => { const id=String(reply.value); bridge.calendarNotifications[id]=true; bridge.delivered(key,id); }, error => bridge.failed(key));
    }
    function flushPending() {
        const queued = bridge.pendingNotifications;
        bridge.pendingNotifications = [];
        for (const note of queued) bridge.deliver(note.key, note.title, note.body);
    }
}
