import QtQuick
import QtTest
import "../package/contents/ui" as UI
Item {
    width: 440; height: 286
    Rectangle { anchors.fill: parent; color: "#090a0e" }
    UI.CalendarBackend { id: realBackend }
    QtObject {
        id: fake
        property date selectedDate: new Date(2026, 10, 3, 12)
        property bool providerAvailable: true
        property string errorMessage: ""
        property var eventDays: ({"2026-11-03":true})
        property var events: [
            {title: "Design review", description: "Discuss the new island", isAllDay: false, startDateTime: new Date(2026,10,3,14), endDateTime: new Date(2026,10,3,15), eventColor: "#c4b5fd"},
            {title: "Release day", description: "", isAllDay: true, eventColor: "#a7e7b8"}
        ]
        function moveDay(delta) { selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate()+delta,12); }
        function resetToday() { selectedDate = new Date(); }
        function reload() {}
    }
    UI.CalendarPage { id: page; x: 22; y: 12; width: 396; height: 240; backend: fake }
    TestCase {
        name: "Calendar"; when: windowShown
        function test_agenda() {
            compare(findChild(page, "eventList").count, 2);
            verify(!findChild(page, "calendarStatus").visible);
            mouseClick(findChild(page, "nextDay")); compare(fake.selectedDate.getDate(), 4);
            mouseClick(findChild(page, "previousDay")); compare(fake.selectedDate.getDate(), 3);
            grabImage(page).save(Qt.resolvedUrl("../docs/calendar.png").toString().replace("file://", ""));
            fake.providerAvailable = false;
            verify(findChild(page, "calendarStatus").visible);
            verify(findChild(page, "calendarStatus").text.indexOf("not installed") >= 0);
        }
        function test_native_date_boundary() {
            verify(realBackend.ready);
            realBackend.selectedDate = new Date(2026, 11, 31, 12);
            realBackend.moveDay(1);
            compare(realBackend.selectedDate.getFullYear(), 2027);
            compare(realBackend.selectedDate.getMonth(), 0);
            compare(realBackend.selectedDate.getDate(), 1);
            realBackend.reload(); wait(50);
            verify(typeof realBackend.events.length === "number");
        }
    }
}
