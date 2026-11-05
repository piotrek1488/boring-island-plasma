import QtQuick
import org.kde.notificationmanager as NM

Item {
    id: backend
    visible: false
    property int previewDuration: 4000
    property bool previewsEnabled: true
    property var known: ({})
    property bool initialized: false
    readonly property alias history: historyModel
    readonly property alias preview: queue.current
    readonly property int count: historyModel.count
    readonly property bool available: NM.Server.valid
    NM.Settings { id: settings; live: true }
    NM.Notifications {
        id: historyModel
        showExpired: true
        showDismissed: true
        showJobs: false
        blacklistedDesktopEntries: settings.historyBlacklistedApplications
        blacklistedNotifyRcNames: settings.historyBlacklistedServices
        urgencies: NM.Notifications.NormalUrgency | NM.Notifications.CriticalUrgency | (settings.lowPriorityHistory ? NM.Notifications.LowUrgency : 0)
        groupMode: NM.Notifications.GroupDisabled
    }
    NotificationQueue {
        id: queue
        duration: backend.previewDuration
        enabled: backend.previewsEnabled && !NM.Server.inhibited
    }
    function value(row, role) { return historyModel.data(historyModel.index(row, 0), role); }
    function scan() {
        const next = {};
        const ids = [];
        // Oldest first so simultaneous arrivals preserve their order.
        for (let row = historyModel.count - 1; row >= 0; --row) {
            const id = String(value(row, NM.Notifications.IdRole));
            const summary = String(value(row, NM.Notifications.SummaryRole) || "");
            const body = String(value(row, NM.Notifications.BodyRole) || "");
            const revision = summary + "\n" + body + "\n" + String(value(row, NM.Notifications.UpdatedRole));
            ids.push(id);
            next[id] = revision;
            if (!initialized || known[id] === revision || value(row, NM.Notifications.ExpiredRole)) continue;
            const desktop = String(value(row, NM.Notifications.DesktopEntryRole) || "");
            const service = String(value(row, NM.Notifications.NotifyRcNameRole) || "");
            if (settings.popupBlacklistedApplications.indexOf(desktop) !== -1 || settings.popupBlacklistedServices.indexOf(service) !== -1) continue;
            if (value(row, NM.Notifications.UrgencyRole) === NM.Notifications.LowUrgency && !settings.lowPriorityPopups) continue;
            if (value(row, NM.Notifications.WasAddedDuringInhibitionRole)) continue;
            const note = {id: id, summary: summary, body: body,
                application: String(value(row, NM.Notifications.ApplicationNameRole) || "")};
            // Progress/text updates must not keep the same preview visible forever.
            if (Object.prototype.hasOwnProperty.call(known, id)) queue.update(note);
            else queue.push(note);
        }
        known = next;
        queue.retain(ids);
        initialized = true;
    }
    function scheduleScan() { Qt.callLater(scan); }
    function closeId(id) {
        for (let row = 0; row < historyModel.count; ++row) {
            if (String(value(row, NM.Notifications.IdRole)) === String(id)) {
                historyModel.close(historyModel.index(row, 0));
                break;
            }
        }
        scan();
    }
    function hidePreviews() { queue.reset(); }
    function clearAll() {
        // Capture IDs first: close() mutates the shared model synchronously.
        const ids = [];
        for (let row = 0; row < historyModel.count; ++row) ids.push(String(value(row, NM.Notifications.IdRole)));
        for (const id of ids) closeId(id);
    }
    Connections {
        target: historyModel
        function onRowsInserted() { backend.scheduleScan(); }
        function onRowsRemoved() { backend.scheduleScan(); }
        function onDataChanged() { backend.scheduleScan(); }
        function onModelReset() { backend.scheduleScan(); }
    }
    Component.onCompleted: Qt.callLater(scan)
}
