import QtQuick
import QtTest
import "../package/contents/ui" as UI

Item {
    ListModel { id: displays }
    UI.BrightnessMonitor { id: monitor; model: displays }
    UI.OsdState { id: osd; duration: 100 }
    Connections { target: monitor; function onChanged(percent, label) { osd.progress("video-display-brightness", percent, 100, label); } }
    SignalSpy { id: changes; target: monitor; signalName: "changed" }
    TestCase {
        name: "BrightnessChanges"; when: windowShown
        function init() {
            displays.clear(); monitor.enabled=true; osd.enabled=true; osd.dismiss();
            displays.append({brightness:400,maxBrightness:1000,label:"Laptop"});
            displays.append({brightness:100,maxBrightness:200,label:"External"});
            wait(20); changes.clear();
        }
        function test_initial_and_hotplug_are_silent() {
            compare(osd.current,null);
            displays.append({brightness:70,maxBrightness:100,label:"New display"}); wait(20);
            compare(changes.count,0); compare(osd.current,null);
            displays.remove(2); wait(20); compare(changes.count,0);
        }
        function test_slider_without_osd_signal_and_multiple_displays() {
            displays.setProperty(0,"brightness",730);
            tryCompare(changes,"count",1); compare(osd.current.value,73); compare(osd.current.description,"Laptop");
            displays.setProperty(1,"brightness",60);
            tryCompare(changes,"count",2); compare(osd.current.value,30); compare(osd.current.description,"External");
            tryCompare(osd,"current",null,500);
        }
        function test_range_changes_and_unchanged_values_are_silent() {
            displays.setProperty(0,"brightness",400); wait(20); compare(changes.count,0);
            displays.set(0,{brightness:800,maxBrightness:2000,label:"Laptop"}); wait(20); compare(changes.count,0);
            displays.setProperty(0,"brightness",1000); tryCompare(changes,"count",1); compare(osd.current.value,50);
        }
        function test_disabled_and_reenabled_do_not_replay_changes() {
            monitor.enabled=false; displays.setProperty(0,"brightness",700); wait(20); compare(changes.count,0);
            monitor.enabled=true; wait(20); compare(changes.count,0);
            displays.setProperty(0,"brightness",710); tryCompare(changes,"count",1); compare(osd.current.value,71);
        }
        function test_rapid_changes_are_coalesced_to_latest_value() {
            displays.setProperty(0,"brightness",600); displays.setProperty(0,"brightness",650); displays.setProperty(0,"brightness",750);
            tryCompare(changes,"count",1); compare(osd.current.value,75);
            displays.setProperty(0,"brightness",2000); tryCompare(changes,"count",2); compare(osd.current.value,100);
        }
    }
}
