import QtQuick
import QtTest
import "../package/contents/ui" as UI
import "../package/contents/code/CalendarMath.js" as CalendarMath

Item {
    width: 650; height: 420
    Rectangle { anchors.fill: parent; color: "#090a0e" }
    QtObject {
        id: fake
        property date selectedDate: new Date(2026, 8, 19, 12)
        property bool providerAvailable: true
        property string errorMessage: ""
        property var eventDays: ({"2026-09-19":true,"2026-09-21":true})
        readonly property var events: selectedDate.getDate() === 19 ? [{title:"Meeting",description:"",isAllDay:false,startDateTime:new Date(2026,8,19,10),endDateTime:new Date(2026,8,19,11)}] : []
        function moveDay(offset) { selectedDate=new Date(selectedDate.getFullYear(),selectedDate.getMonth(),selectedDate.getDate()+offset,12); }
        function resetToday() { selectedDate=new Date(); }
        function reload() {}
    }
    UI.CalendarPage { id: page; width: 568; height: 200; backend: fake }
    TestCase {
        name: "MonthCalendar"; when: windowShown
        function init() {
            fake.selectedDate=new Date(2026,8,19,12); page.language="en";
            page.width=568; page.height=200; wait(30);
        }
        function test_events_left_month_right_data() {
            return [{tag:"default",width:568,height:200},{tag:"narrow",width:388,height:200},{tag:"compact",width:388,height:154}];
        }
        function test_events_left_month_right(data) {
            page.width=data.width; page.height=data.height; wait(30);
            const events=findChild(page,"calendarEventsPane"), month=findChild(page,"calendarMonthPane");
            verify(events.x+events.width<month.x);
            verify(month.x+month.width<=page.width+1);
            const last=findChild(page,"calendarDay_2026-10-11");
            verify(last !== null); verify(last.height>=16);
            const bottom=last.mapToItem(page,last.width,last.height);
            verify(bottom.y<=page.height+1);
            compare(findChild(page,"eventList").count,1);
        }
        function test_select_day_updates_agenda() {
            mouseClick(findChild(page,"calendarDay_2026-09-21"));
            compare(fake.selectedDate.getDate(),21); compare(findChild(page,"eventList").count,0);
            verify(findChild(page,"calendarDay_2026-09-21").selected);
            mouseClick(findChild(page,"calendarDay_2026-09-19"));
            compare(findChild(page,"eventList").count,1);
        }
        function test_month_navigation_clamps_day_and_year() {
            fake.selectedDate=new Date(2026,0,31,12); wait(20);
            mouseClick(findChild(page,"nextMonth"));
            compare(CalendarMath.key(fake.selectedDate),"2026-02-28");
            fake.selectedDate=new Date(2026,11,15,12); wait(20);
            mouseClick(findChild(page,"nextMonth")); compare(CalendarMath.key(fake.selectedDate),"2027-01-15");
            mouseClick(findChild(page,"previousMonth")); compare(CalendarMath.key(fake.selectedDate),"2026-12-15");
        }
        function test_leap_year_and_week_start() {
            compare(CalendarMath.key(CalendarMath.moveMonth(new Date(2024,0,31,12),1)),"2024-02-29");
            const monday=CalendarMath.monthDays(new Date(2026,8,19,12),1);
            compare(monday.length,42); compare(monday[0].getDay(),1); compare(CalendarMath.key(monday[0]),"2026-08-31");
            const sunday=CalendarMath.monthDays(new Date(2026,8,19,12),7);
            compare(sunday[0].getDay(),0); compare(CalendarMath.key(sunday[0]),"2026-08-30");
        }
        function test_markers_today_and_language() {
            verify(findChild(page,"eventDot_2026-09-19").visible);
            verify(!findChild(page,"eventDot_2026-09-20").visible);
            page.language="pl";
            verify(findChild(page,"monthTitle").text.indexOf("września")>=0 || findChild(page,"monthTitle").text.indexOf("wrzesień")>=0);
            mouseClick(findChild(page,"todayButton"));
            compare(CalendarMath.key(fake.selectedDate),CalendarMath.key(new Date()));
            verify(findChild(page,"calendarDay_"+CalendarMath.key(new Date())).currentDay);
        }
    }
}
