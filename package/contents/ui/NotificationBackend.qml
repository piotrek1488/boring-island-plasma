import QtQuick
import org.kde.notificationmanager as NM

Item {
    id: backend
    visible: false
    property int previewDuration: 4000
    property bool previewsEnabled: true
    readonly property alias history: historyModel
    readonly property alias preview: feed.preview
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
    NotificationFeed {
        id: feed
        duration: backend.previewDuration
        previewsEnabled: backend.previewsEnabled && !NM.Server.inhibited
    }
    // Preview arrivals must not depend on history preferences or its urgency filter.
    NM.Notifications {
        id: arrivals
        showExpired: true
        showDismissed: true
        showJobs: false
        groupMode: NM.Notifications.GroupDisabled
    }
    function value(row, role) { return arrivals.data(arrivals.index(row, 0), role); }
    function scan() {
        const notes = [];
        for (let row = arrivals.rowCount() - 1; row >= 0; --row) {
            const desktop = String(value(row, NM.Notifications.DesktopEntryRole) || "");
            const service = String(value(row, NM.Notifications.NotifyRcNameRole) || "");
            const allowed = settings.popupBlacklistedApplications.indexOf(desktop) === -1
                && settings.popupBlacklistedServices.indexOf(service) === -1
                && (value(row, NM.Notifications.UrgencyRole) !== NM.Notifications.LowUrgency || settings.lowPriorityPopups)
                && !value(row, NM.Notifications.WasAddedDuringInhibitionRole);
            notes.push({id: String(value(row, NM.Notifications.IdRole)),
                summary: String(value(row, NM.Notifications.SummaryRole) || ""),
                body: String(value(row, NM.Notifications.BodyRole) || ""),
                application: String(value(row, NM.Notifications.ApplicationNameRole) || ""),
                updated: String(value(row, NM.Notifications.UpdatedRole)), allowed: allowed});
        }
        feed.sync(notes);
    }
    function scheduleScan() { Qt.callLater(scan); }
    function closeId(id) {
        for (let row = 0; row < arrivals.rowCount(); ++row) {
            if (String(value(row, NM.Notifications.IdRole)) === String(id)) {
                arrivals.close(arrivals.index(row, 0));
                break;
            }
        }
        feed.removed(id);
        scheduleScan();
    }
    function hidePreviews() { feed.reset(); }
    function clearAll() {
        // Capture IDs first: close() mutates the shared model synchronously.
        const ids = [];
        for (let row = 0; row < historyModel.count; ++row) ids.push(String(historyModel.data(historyModel.index(row, 0), NM.Notifications.IdRole)));
        for (const id of ids) closeId(id);
    }
    Connections {
        target: arrivals
        function onRowsInserted() { backend.scan(); }
        function onRowsRemoved() { backend.scheduleScan(); }
        function onDataChanged() { backend.scheduleScan(); }
        function onModelReset() { backend.scheduleScan(); }
    }
    Component.onCompleted: scan()
}
