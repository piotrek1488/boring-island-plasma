import QtQuick
import QtTest
import "../package/contents/ui" as UI

Item {
    id: fixture
    function at(day,hour,minute) { return new Date(2026,10,day,hour,minute || 0); }
    UI.ReminderScheduler { id: scheduler; autoTick:false; onStateEdited: json=>stateJson=json }
    SignalSpy { id: spy; target:scheduler; signalName:"reminder" }
    TestCase {
        name:"CalendarReminders"; when:windowShown
        function init() {
            scheduler.enabled=false; scheduler.pending=({}); scheduler.stateJson="{}";
            scheduler.events=[]; scheduler.leadMinutes=15; scheduler.currentTime=at(5,9,44); spy.clear();
        }
        function event(day=5,hour=10,minute=0) { return {uid:"meeting",sourceKey:"calendar-a",title:"Meeting",startDateTime:at(day,hour,minute),endDateTime:at(day,hour+1,minute),isAllDay:false}; }
        function test_before_and_start_once_and_persisted_state() {
            scheduler.events=[event(),event()]; scheduler.enabled=true; wait(10); compare(spy.count,0);
            scheduler.currentTime=at(5,9,45); compare(spy.count,1); compare(spy.signalArguments[0][1],"before");
            const beforeKey=spy.signalArguments[0][2]; scheduler.acknowledge(beforeKey);
            scheduler.events=[event()]; scheduler.evaluate(); compare(spy.count,1);
            scheduler.currentTime=at(5,10,0); compare(spy.count,2); compare(spy.signalArguments[1][1],"start");
            scheduler.acknowledge(spy.signalArguments[1][2]);
            scheduler.pending=({}); scheduler.evaluate(); compare(spy.count,2);
            const saved=JSON.parse(scheduler.stateJson); compare(Object.keys(saved).length,2);
        }
        function test_midnight_and_recurrence_occurrences() {
            scheduler.currentTime=at(5,23,49); scheduler.events=[event(6,0,5)]; scheduler.enabled=true; wait(10);
            compare(spy.count,0); scheduler.currentTime=at(5,23,50); compare(spy.count,1);
            scheduler.acknowledge(spy.signalArguments[0][2]);
            scheduler.currentTime=at(6,0,5); compare(spy.count,2);
            scheduler.acknowledge(spy.signalArguments[1][2]);
            scheduler.events=[event(7,0,5)]; scheduler.currentTime=at(6,23,50); compare(spy.count,3);
        }
        function test_all_day_zero_lead_and_stale_events() {
            const allDay=event(); allDay.isAllDay=true;
            scheduler.events=[allDay,event()]; scheduler.leadMinutes=0;
            scheduler.currentTime=at(5,9,59); scheduler.enabled=true; wait(10); compare(spy.count,0);
            scheduler.currentTime=at(5,10,0); compare(spy.count,1);
            scheduler.acknowledge(spy.signalArguments[0][2]);
            scheduler.stateJson="{}"; scheduler.currentTime=at(5,10,5); compare(spy.count,1);
        }
        function test_failed_delivery_retries_and_disabled_state() {
            scheduler.events=[event()]; scheduler.currentTime=at(5,9,46); scheduler.enabled=true; wait(10); compare(spy.count,1);
            scheduler.evaluate(); compare(spy.count,1);
            scheduler.currentTime=new Date(at(5,9,46).getTime()+31000); compare(spy.count,2);
            scheduler.enabled=false; scheduler.currentTime=at(5,10); compare(spy.count,2);
        }
    }
}
