import QtQuick
import QtTest
import "../package/contents/ui" as UI

Item {
    width: 620; height: 250
    QtObject {
        id: backend
        property int actionRevision: 0
        property bool actionable: true
        property string openedId: ""
        property string deletedId: ""
        signal applicationLaunchFinished(string id, bool success)
        function canOpenId(id) { return actionable && String(id)==="42"; }
        function openId(id,window) { if (!canOpenId(id)) return false; openedId=String(id); return true; }
        function closeId(id) { deletedId=String(id); }
    }
    UI.NotificationCard {
        id: card; width: 580; height: 120; backend:backend
        note: ({id:"42",application:"Mail",summary:"New message",body:"Message body"})
    }
    SignalSpy { id: opened; target:card; signalName:"applicationOpened" }
    TestCase {
        name:"NotificationActions"; when:windowShown
        function init() { backend.actionable=true; backend.actionRevision++; backend.openedId=""; backend.deletedId=""; opened.clear(); mouseMove(card,610,200); wait(20); }
        function test_open_icon_before_delete() {
            const launch=findChild(card,"openNotification_42"), close=findChild(card,"deleteNotification_42");
            verify(launch.x<close.x);
            mouseClick(launch); compare(backend.openedId,"42"); compare(backend.deletedId,""); compare(opened.count,1);
        }
        function test_row_click_and_highlight() {
            const base=card.color.toString(); mouseMove(card,30,30); wait(20); verify(card.color.toString()!==base);
            mouseClick(card,30,30); compare(backend.openedId,"42"); compare(opened.count,1); compare(backend.deletedId,"");
        }
        function test_delete_does_not_open_application() {
            mouseClick(findChild(card,"deleteNotification_42")); compare(backend.deletedId,"42"); compare(backend.openedId,""); compare(opened.count,0);
        }
        function test_missing_action_and_async_launch() {
            backend.actionable=false; backend.actionRevision++;
            verify(!findChild(card,"openNotification_42").enabled);
            mouseClick(card,30,30); compare(backend.openedId,""); compare(opened.count,0);
            backend.applicationLaunchFinished("other",true); compare(opened.count,0);
            backend.applicationLaunchFinished("42",false); compare(opened.count,0);
            backend.applicationLaunchFinished("42",true); compare(opened.count,1);
        }
    }
}
