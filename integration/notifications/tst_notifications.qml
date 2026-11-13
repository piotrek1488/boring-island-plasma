// Run only in an isolated D-Bus session, never against the live desktop bus.
import QtQuick
import QtTest
import org.kde.notificationmanager as NM
import org.kde.plasma.plasma5support as Plasma5Support
import "../../package/contents/ui" as UI

TestCase {
    id: test
    name: "SharedNotificationHistory"
    when: windowShown
    visible: true
    width: 600; height: 400
    property int serial: 0
    property bool commandDone: false
    property int commandExit: -1
    UI.NotificationBackend { id: backend; previewDuration: 1000 }
    // The fixture's runner.cpp owns the notification service, so the server is
    // ready for the suite by default; the queueing test toggles this itself.
    UI.NativeServices { id: nativeBridge; osdEnabled:false; notificationsReady:true }
    SignalSpy { id: reminderOpenedSpy; target:nativeBridge; signalName:"reminderActivated" }
    SignalSpy { id: deliveredSpy; target:nativeBridge; signalName:"delivered" }
    NM.Notifications { id: center; showExpired: true; showDismissed: true; groupMode: NM.Notifications.GroupDisabled }
    Plasma5Support.DataSource {
        id: sender
        engine: "executable"
        onNewData: (source, data) => {
            test.commandExit = data["exit code"];
            test.commandDone = true;
            disconnectSource(source);
        }
    }
    UI.NotificationsPage { id: page; width: 600; height: 380; backend: backend }
    function send(expectedHistoryCount = 1, expectedCenterCount = 1) {
        commandDone = false;
        serial++;
        sender.connectSource("gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.Notify BoringIslandTest 0 '' 'Fixture " + serial + "' 'Test body' '[]' '{}' 0");
        tryVerify(() => commandDone, 5000);
        compare(commandExit, 0);
        tryCompare(backend, "count", expectedHistoryCount, 3000);
        tryCompare(center, "count", expectedCenterCount, 3000);
        tryVerify(() => backend.preview !== null, 3000);
    }
    function initTestCase() {
        verify(NM.Server.valid);
        wait(100); // Finish seeding existing history before sending fixtures.
    }
    function cleanup() {
        for (let row=center.count-1;row>=0;--row) center.close(center.index(row,0));
        backend.hidePreviews(); tryCompare(center,"count",0);
        backend.history.blacklistedDesktopEntries=[];
    }
    function init() {
        // Synthetic senders have no desktop entry and use KDE's fallback service.
        // Do not let the user's/default @other blacklist hide fixture history.
        backend.history.blacklistedDesktopEntries=[];
        backend.history.blacklistedNotifyRcNames=[];
        // Reset readiness so the queueing test cannot leak state into others.
        // Clear the queue BEFORE marking ready: setting notificationsReady=true
        // triggers flushPending(), which would otherwise deliver leftovers into
        // the next test's history.
        nativeBridge.pendingNotifications=[];
        nativeBridge.notificationsReady=true;
    }
    function test_notify_is_queued_while_server_not_ready() {
        // Regression: sending Notify before plasmashell owns the notification
        // name crashed the libdbusplugin reply decoder (SIGSEGV, boring-island
        // crash loop on shell startup). notify() must NOT call asyncCall while
        // the server is not ready; it queues instead, preserving order, and
        // only deliver()s once ready. See docs/issues/0001-*.md.
        //
        // This asserts the gate and the queue only. It intentionally does not
        // drive the real Notify/reply path, because the synthetic fixture
        // server returns a reply shape the stripped libdbusplugin decoder
        // crashes on in offscreen mode (unrelated to this fix; the live Plasma
        // server returns a well-formed uint32 and the full delivery path is
        // covered by test_native_reminder_joins_shared_history).
        deliveredSpy.clear(); reminderOpenedSpy.clear();
        nativeBridge.notificationsReady = false;
        nativeBridge.notify("k1","Standup","Standup at 09:30");
        nativeBridge.notify("k2","Review","Review at 10:00");
        // Nothing delivered while not ready; both requests are held, in order.
        compare(deliveredSpy.count, 0);
        compare(nativeBridge.pendingNotifications.length, 2);
        compare(String(nativeBridge.pendingNotifications[0].key), "k1");
        compare(String(nativeBridge.pendingNotifications[1].key), "k2");
        compare(String(nativeBridge.pendingNotifications[0].title), "Standup");
        // Drop the queued entries without flushing, so they are never delivered
        // into another test's history. Clear before init() marks ready again.
        nativeBridge.pendingNotifications=[];
    }
    function test_native_reminder_joins_shared_history() {
        deliveredSpy.clear(); reminderOpenedSpy.clear();
        nativeBridge.notificationsReady = true;
        nativeBridge.notify("fixture-reminder","Meeting starts","Meeting <fixture> at 10:00");
        tryCompare(deliveredSpy,"count",1,3000);
        tryCompare(backend,"count",1,3000); tryCompare(center,"count",1,3000);
        const id=deliveredSpy.signalArguments[0][1];
        verify(backend.canOpenId(id)); verify(backend.openId(id,null));
        tryCompare(reminderOpenedSpy,"count",1,3000);
        tryCompare(center,"count",0,3000); tryCompare(backend,"count",0,3000);
        tryCompare(backend,"preview",null,3000);
    }
    function test_preview_independent_of_history_filter() {
        backend.history.blacklistedDesktopEntries=["@other"];
        send(0);
        const id=backend.preview.id;
        backend.closeId(id);
        tryCompare(center,"count",0);
        tryCompare(backend,"preview",null);
    }
    function test_async_launch_success_and_failure() {
        send();
        const id=backend.preview.id;
        backend.completeAsyncLaunch(id,false);
        compare(center.count,1); compare(backend.count,1); compare(backend.preview.id,id);
        backend.completeAsyncLaunch(id,true);
        tryCompare(center,"count",0); tryCompare(backend,"count",0); tryCompare(backend,"preview",null);
    }
    function test_shared_launch_removes_each_clicked_notification() {
        send(); const first=backend.preview.id;
        send(2,2);
        const ids=[];
        for (let row=0; row<backend.history.rowCount(); ++row) ids.push(String(backend.history.data(backend.history.index(row,0),NM.Notifications.IdRole)));
        const second=ids.find(id=>id!==first);
        const command="python3 -c 'import time; time.sleep(0.1)'";
        backend.launchApplication(command,first);
        backend.launchApplication(command,second);
        tryCompare(backend,"count",0,3000); tryCompare(center,"count",0,3000);
    }
    function test_timeout_keeps_both_histories() {
        send();
        tryCompare(backend, "preview", null, 2000);
        compare(backend.count, 1);
        compare(center.count, 1);
    }
    function test_delete_from_island() {
        send();
        backend.closeId(backend.preview.id);
        tryCompare(center, "count", 0);
        tryCompare(backend, "preview", null);
    }
    function test_individual_delete_button_uses_native_role() {
        send(); send(2,2);
        const id=backend.history.data(backend.history.index(0,0),NM.Notifications.IdRole);
        tryVerify(() => findChild(page,"deleteNotification_"+id) !== null);
        verify(waitForRendering(page));
        mouseClick(findChild(page,"deleteNotification_"+id));
        tryCompare(center,"count",1); tryCompare(backend,"count",1);
        verify(backend.history.data(backend.history.index(0,0),NM.Notifications.IdRole)!==id);
    }
    function test_delete_from_center() {
        send();
        center.close(center.index(0, 0));
        tryCompare(backend, "count", 0);
        tryCompare(backend, "preview", null);
    }
    function test_expired_can_be_deleted() {
        send();
        center.expire(center.index(0, 0));
        compare(center.count, 1);
        compare(backend.count, 1);
        backend.clearAll();
        tryCompare(center, "count", 0);
    }
}
