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
    width: 600; height: 400
    property int serial: 0
    property bool commandDone: false
    property int commandExit: -1
    UI.NotificationBackend { id: backend; previewDuration: 1000 }
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
        verify(NM.Server.init());
        verify(NM.Server.valid);
        wait(100); // Finish seeding existing history before sending fixtures.
    }
    function cleanup() {
        for (let row=center.count-1;row>=0;--row) center.close(center.index(row,0));
        backend.hidePreviews(); tryCompare(center,"count",0);
        backend.history.blacklistedDesktopEntries=[];
    }
    function test_preview_independent_of_history_filter() {
        backend.history.blacklistedDesktopEntries=["@other"];
        send(0);
        const id=backend.preview.id;
        backend.closeId(id);
        tryCompare(center,"count",0);
        tryCompare(backend,"preview",null);
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
