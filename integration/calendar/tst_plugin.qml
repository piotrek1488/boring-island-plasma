import QtQuick
import QtTest
import "../../package/contents/ui" as UI
Item {
    UI.CalendarBackend { id: backend; selectedDate: new Date(2026, 10, 3, 12) }
    TestCase {
        name: "NativeCalendarPlugin"; when: windowShown
        function test_native_provider() {
            verify(backend.providerAvailable);
            tryVerify(() => backend.events.length > 0, 5000);
            compare(backend.events[0].title, "Native event 2026-11-03");
            compare(backend.events.length, 1);
            compare(backend.events[0].startDateTime.getHours(), 14);
            backend.selectedDate = new Date(2026, 11, 31, 12);
            tryVerify(() => backend.events.length > 0 && backend.events[0].title === "Native event 2026-12-31", 5000);
            backend.moveDay(1);
            tryVerify(() => backend.events.length > 0 && backend.events[0].title === "Native event 2027-01-01", 5000);
            backend.reload();
            tryVerify(() => backend.events.length === 1, 5000);
        }
    }
}
