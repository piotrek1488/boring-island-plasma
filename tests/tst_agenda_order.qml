import QtQuick
import QtTest
import "../package/contents/ui" as UI
import "../package/contents/code/AgendaOrder.js" as AgendaOrder

Item {
    width: 600; height: 260
    function at(hour, minute) { return new Date(2026,10,5,hour,minute || 0); }
    QtObject {
        id: fake
        property date selectedDate: new Date(2026,10,5,12)
        property bool providerAvailable: true
        property string errorMessage: ""
        property var eventDays: ({})
        property var events: []
        function moveDay(offset) {}
        function resetToday() {}
        function reload() {}
    }
    UI.CalendarPage { id: page; width: 568; height: 210; backend: fake }
    TestCase {
        name: "AgendaOrder"; when: windowShown
        function init() {
            fake.selectedDate=new Date(2026,10,5,12);
            fake.events=[
                {title:"Past",startDateTime:at(9),endDateTime:at(10)},
                {title:"Future",startDateTime:at(12),endDateTime:at(13)},
                {title:"Ongoing",startDateTime:at(10),endDateTime:at(11)},
                {title:"All day",isAllDay:true,startDateTime:at(0),endDateTime:new Date(2026,10,6,0)},
                {title:"Soon",startDateTime:at(10,45),endDateTime:at(11,15)},
                {title:"Early",startDateTime:at(7),endDateTime:at(8)}
            ];
            page.currentTime=at(10,30); wait(30);
        }
        function test_ongoing_then_upcoming_and_past_last() {
            compare(page.eventOrder,"2,4,1,3,0,5");
            compare(page.orderedEvents[0].title,"Ongoing");
            compare(findChild(page,"eventList").count,6);
        }
        function test_nearest_upcoming_when_nothing_ongoing() {
            page.currentTime=at(10,5);
            fake.events=fake.events.filter(e=>e.title!=="Ongoing");
            compare(page.orderedEvents[0].title,"Soon");
        }
        function test_clock_update_and_exclusive_end() {
            page.currentTime=at(11);
            compare(page.orderedEvents[0].title,"Soon");
            page.currentTime=at(11,16);
            compare(page.orderedEvents[0].title,"Future");
            page.currentTime=at(14);
            compare(page.orderedEvents[0].title,"All day");
            compare(page.orderedEvents[1].title,"Future");
        }
        function test_other_dates_are_chronological() {
            fake.selectedDate=new Date(2026,10,6,12);
            compare(page.eventOrder,"3,5,0,2,4,1");
            fake.selectedDate=new Date(2026,10,4,12);
            compare(page.eventOrder,"3,5,0,2,4,1");
        }
        function test_same_order_keeps_scroll_position() {
            const list=findChild(page,"eventList");
            list.contentY=60;
            page.currentTime=at(10,31); wait(20);
            compare(page.eventOrder,"2,4,1,3,0,5");
            compare(list.contentY,60);
        }
        function test_returning_to_today_starts_at_current_event() {
            fake.selectedDate=new Date(2026,10,6,12); wait(20);
            const list=findChild(page,"eventList"); list.contentY=60;
            fake.selectedDate=new Date(2026,10,5,12);
            tryCompare(list,"contentY",0);
            compare(page.orderedEvents[0].title,"Ongoing");
        }
        function test_overnight_zero_length_and_missing_times() {
            const rows=[
                {startDateTime:new Date(2026,10,4,23),endDateTime:at(11)},
                {startDateTime:at(10,30)},
                {startDateTime:"invalid"},
                {startDateTime:at(8),endDateTime:at(9)}
            ];
            compare(AgendaOrder.indices(rows,fake.selectedDate,at(10,30)).join(","),"0,1,3,2");
            compare(AgendaOrder.indices([],fake.selectedDate,at(10,30)).length,0);
        }
    }
}
