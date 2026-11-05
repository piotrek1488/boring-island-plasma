import QtQuick
import QtTest
import "../package/contents/ui" as UI
import "../package/contents/code/Activity.js" as Activity

Item {
    id: scene
    width: 600; height: 240
    property string pin: "notifications"
    property int shelfCount: 0
    property int notificationCount: 0
    readonly property string mode: osd.active ? "osd" : Activity.resolve(pin,queue.current!==null,false,media.playing,false,shelfCount,notificationCount)
    QtObject {
        id: media
        property bool playing: true
        property string title: "movie.mp4"
        property bool hasBattery: true
        property int percent: 75
        property string batteryStatus: "discharging"
        property double position: 65000000
        property double duration: 180000000
        property int pauseCalls: 0
        function toggle() { pauseCalls++; playing=!playing; }
    }
    UI.OsdState { id: osd; duration: 100 }
    UI.NotificationQueue { id: queue; duration: 1000; suspended: osd.active }
    UI.CompactView {
        id: compact; width: 320; height: 42; backend: media
        displayText: scene.mode==="notifications" ? (queue.current ? queue.current.summary : "Notifications") : scene.mode==="media" ? media.title : "12:30"
        alternateText: Activity.timeLabel(media.position)+" / "+Activity.timeLabel(media.duration)
        cycleText: scene.mode==="media"; cycleInterval: 1000
        osd: osd.current; reduceMotion: true
    }
    TestCase {
        name: "CompactActivities"; when: windowShown
        function init() {
            queue.reset(); osd.dismiss(); osd.enabled=true; osd.duration=100;
            scene.pin="notifications"; scene.shelfCount=0; scene.notificationCount=0;
            media.playing=true; media.position=65000000; media.pauseCalls=0;
            compact.reduceMotion=true; compact.batteryOnly=false; compact.cycleText=Qt.binding(()=>scene.mode==="media");
            findChild(compact,"compactTextViewport").reset();
            wait(20);
        }
        function test_dynamic_priorities() {
            compare(scene.mode,"media");
            scene.shelfCount=3; compare(scene.mode,"media");
            media.playing=false; compare(scene.mode,"shelf"); compare(Activity.page(scene.mode),1);
            scene.shelfCount=0; compare(scene.mode,"clock");
            scene.notificationCount=2; compare(scene.mode,"notifications");
            compare(Activity.resolve("clock",false,true,true,true,10,10),"media");
            compare(Activity.resolve("notifications",false,false,false,false,0,0),"clock");
            compare(Activity.resolve("notifications",false,false,false,false,0,2),"notifications");
        }
        function test_media_rotates_without_playback_commands() {
            const title=findChild(compact,"compactTitle");
            compare(title.text,"movie.mp4");
            tryCompare(title,"text","1:05 / 3:00",1600);
            queue.push({id:"message",summary:"New message"});
            compare(title.text,"New message");
            media.position=125000000;
            tryCompare(queue,"current",null,1400);
            compare(scene.mode,"media"); compare(title.text,"movie.mp4");
            tryCompare(title,"text","2:05 / 3:00",1600);
            verify(media.playing); compare(media.pauseCalls,0);
        }
        function test_osd_preserves_notifications_and_returns_to_media() {
            queue.push({id:"message",summary:"Message"}); wait(100);
            osd.duration=1200; osd.progress("audio-volume-high",70,100,"");
            compare(scene.mode,"osd"); verify(findChild(compact,"compactOsd").visible);
            verify(!findChild(compact,"compactBattery").visible);
            wait(1050); compare(queue.current.id,"message");
            tryCompare(osd,"current",null,500); compare(scene.mode,"notifications");
            verify(queue.current!==null);
            media.position=150000000;
            tryCompare(queue,"current",null,1500); compare(scene.mode,"media");
            compare(media.pauseCalls,0); verify(media.playing);
        }
        function test_osd_bounds_reset_and_filter() {
            osd.progress("video-display-brightness",60,100,"Display");
            compare(osd.current.kind,"brightness"); compare(osd.current.value,60);
            osd.progress("audio-volume-high",180,150,""); compare(osd.current.value,150);
            osd.text("audio-volume-muted","Muted"); compare(osd.current.value,0);
            osd.progress("microphone",50,100,""); compare(osd.current.value,0);
            osd.progress("audio-volume-high",50,0,""); compare(osd.current.value,0);
            osd.enabled=false; verify(!osd.active);
        }
        function test_vertical_media_transition_moves_up() {
            compact.reduceMotion=false;
            const label=findChild(compact,"compactTextViewport"), title=findChild(compact,"compactTitle");
            label.reset();
            tryCompare(label,"transitioning",true,1500); wait(30);
            verify(title.y<0); verify(label.progress>0 && label.progress<1);
            tryCompare(label,"transitioning",false,500);
            compare(title.text,"1:05 / 3:00");
        }
        function test_battery_only_and_time_format() {
            compact.batteryOnly=true; wait(20);
            verify(!findChild(compact,"compactTitle").visible);
            verify(findChild(compact,"compactBattery").visible);
            compare(Activity.timeLabel(3661000000),"1:01:01"); compare(Activity.timeLabel(-10),"0:00");
        }
        function test_idle_date_has_no_time_and_updates_at_midnight() {
            const locale=Qt.locale("en_GB"), before=new Date(2026,10,5,23,59), after=new Date(2026,10,6,0,0);
            compare(Activity.idleText("date",before,locale),"5 Nov 2026");
            compare(Activity.idleText("date",after,locale),"6 Nov 2026");
            compare(Activity.idleText("clock",before,locale),"23:59");
            compare(Activity.idleText("dateClock",before,locale),"5 Nov 2026 · 23:59");
        }
    }
}
