import QtQuick
import org.kde.notificationmanager as NM
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: backend
    visible: false
    signal applicationLaunchFinished(string id, bool success)
    property var launches: ({})
    readonly property string launchScript: decodeURIComponent(Qt.resolvedUrl("../code/launch_application.py").toString().replace(/^file:\/\//,""))
    function quote(value) { return "'"+String(value).replace(/'/g,"'\\''")+"'"; }
    Plasma5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: (source,data) => {
            disconnectSource(source);
            const id=backend.launches[source]; delete backend.launches[source];
            backend.applicationLaunchFinished(String(id),data["exit code"]===0);
        }
    }
    property int actionRevision: 0
    property bool previewsSuspended: false
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
        suspended: backend.previewsSuspended
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
        actionRevision++;
    }
    function scheduleScan() { Qt.callLater(scan); }
    function actionRow(id) {
        if (id === undefined || id === null) return -1;
        for (let row=0;row<arrivals.rowCount();++row) if (String(value(row,NM.Notifications.IdRole))===String(id)) return row;
        return -1;
    }
    function canOpenId(id) {
        const row=actionRow(id);
        return row>=0 && (Boolean(value(row,NM.Notifications.HasDefaultActionRole)) || /^[A-Za-z0-9_.-]{1,250}$/.test(String(value(row,NM.Notifications.DesktopEntryRole) || "")));
    }
    function openId(id, window) {
        const row=actionRow(id);
        if (row<0) return false;
        if (value(row,NM.Notifications.HasDefaultActionRole)) {
            if (window) arrivals.window=window;
            arrivals.invokeDefaultAction(arrivals.index(row,0), NM.Notifications.None);
            return true;
        }
        const entry=String(value(row,NM.Notifications.DesktopEntryRole) || "");
        if (!/^[A-Za-z0-9_.-]{1,250}$/.test(entry)) return false;
        const command="python3 "+quote(launchScript)+" --desktop-id "+quote(entry);
        if (launches[command]===undefined) { launches[command]=String(id); launcher.connectSource(command); }
        return false; // The asynchronous launcher reports success separately.
    }
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
