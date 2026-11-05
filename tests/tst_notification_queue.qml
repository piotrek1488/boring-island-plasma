import QtQuick
import QtTest
import "../package/contents/ui" as UI
import "../package/contents/code/Activity.js" as Activity

TestCase {
    name: "NotificationQueue"
    UI.NotificationQueue { id: queue }
    UI.NotificationFeed { id: feed; duration: 1000 }
    function init() { queue.reset(); queue.enabled = true; queue.duration = 1000; }
    function test_expiry_keeps_history_separate() {
        queue.push({id: "a", summary: "First"});
        verify(queue.active);
        tryCompare(queue, "active", false, 1600);
        compare(queue.current, null);
    }
    function test_order_and_replacement() {
        queue.push({id: "a", summary: "First"});
        queue.push({id: "b", summary: "Second"});
        queue.push({id: "b", summary: "Updated"});
        compare(queue.pending.length, 1);
        queue.next();
        compare(queue.current.summary, "Updated");
        queue.push({id: "b", summary: "Replaced"});
        compare(queue.current.summary, "Replaced");
        compare(queue.pending.length, 0);
    }
    function test_updates_do_not_extend_preview() {
        queue.push({id: "a", summary: "Start"});
        wait(600);
        queue.push({id: "a", summary: "Updated"});
        compare(queue.current.summary, "Updated");
        tryCompare(queue, "active", false, 650);
        queue.update({id: "a", summary: "Another update"});
        verify(!queue.active);
    }
    function test_external_deletion() {
        queue.push({id: "a"}); queue.push({id: "b"}); queue.push({id: "c"});
        queue.retain(["b"]);
        compare(queue.current.id, "b");
        compare(queue.pending.length, 0);
        queue.retain([]);
        verify(!queue.active);
    }
    function test_disabled_and_bounded() {
        queue.enabled = false; queue.push({id: "a"}); verify(!queue.active);
        queue.enabled = true;
        for (let i = 0; i < 40; ++i) queue.push({id: String(i)});
        compare(queue.pending.length, 20);
        queue.enabled = false;
        verify(!queue.active); compare(queue.pending.length, 0);
    }
    function test_live_feed_and_expired_arrival() {
        feed.reset(); feed.initialized=false;
        feed.sync([{id:"old",summary:"Old",body:"",updated:"",allowed:true}]);
        compare(feed.preview,null);
        const fresh={id:"fresh",summary:"New",body:"Message",updated:"",allowed:true,expired:true};
        feed.sync([fresh]);
        compare(feed.preview.id,"fresh");
        feed.sync([]); compare(feed.preview,null);
    }
    function test_live_feed_respects_suppression() {
        feed.reset(); feed.initialized=false; feed.sync([]);
        feed.sync([{id:"muted",summary:"Muted",body:"",updated:"",allowed:false}]);
        compare(feed.preview,null);
        feed.sync([{id:"next",summary:"New",body:"",updated:"",allowed:true}]);
        compare(feed.preview.id,"next");
        feed.removed("next"); compare(feed.preview,null);
    }
    function test_priority() {
        compare(Activity.resolve("auto", true, true, true, true), "notifications");
        compare(Activity.resolve("auto", false, true, true, true), "packages");
        compare(Activity.resolve("auto", false, false, true, true), "media");
        compare(Activity.resolve("auto", false, false, false, true), "llm");
        compare(Activity.resolve("auto", false, false, false, false), "clock");
        compare(Activity.resolve("clock", false, true, true, true), "clock");
        compare(Activity.resolve("clock", true, true, true, true), "notifications");
        compare(Activity.resolve("notifications",false,true,true,true),"notifications");
        compare(Activity.page("notifications"), 4);
        compare(Activity.page("packages"), 5);
    }
}
