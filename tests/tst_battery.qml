import QtQuick
import QtTest
import "../package/contents/ui" as UI

Item {
    width: 700; height: 180
    QtObject {
        id: fake
        property string title: "Test track"
        property bool playing: false
        property bool hasBattery: true
        property int percent: 82
        property bool charging: false
        property string batteryStatus: "discharging"
    }
    UI.CompactView { id: compact; width: 520; height: 56; expandedHeader: true; backend: fake }
    UI.BatteryIndicator { id: indicator; y: 90; percent: 82 }
    SignalSpy { id: configureSpy; target: compact; signalName: "configureRequested" }
    SignalSpy { id: activationSpy; target: compact; signalName: "activated" }
    TestCase {
        name: "BatteryAndSettings"; when: windowShown
        function init() {
            indicator.percentPosition="right"; indicator.status="discharging"; indicator.language="en";
            compact.expandedHeader=true; compact.showBattery=true; compact.configureEnabled=true;
            compact.batteryPercentPosition="right"; fake.hasBattery=true;
            configureSpy.clear(); activationSpy.clear();
        }
        function test_percentage_positions_data() {
            return ["inside","left","right","hidden"].map(p => ({tag:p,position:p}));
        }
        function test_percentage_positions(data) {
            indicator.percentPosition=data.position; wait(30);
            compare(findChild(indicator,"batteryPercentInside").visible,data.position==="inside");
            compare(findChild(indicator,"batteryPercentLeft").visible,data.position==="left");
            compare(findChild(indicator,"batteryPercentRight").visible,data.position==="right");
            verify(findChild(indicator,"batteryIcon").visible);
        }
        function test_power_states() {
            indicator.status="plugged";
            compare(indicator.statusText,"Plugged in, not charging");
            verify(!indicator.hasStatusMark);
            indicator.status="charging"; compare(indicator.statusText,"Charging"); verify(indicator.hasStatusMark);
            wait(30); verify(findChild(indicator,"batteryStatusMark").x < findChild(indicator,"batteryIcon").x);
            indicator.status="full"; compare(indicator.statusText,"Fully charged"); verify(!indicator.hasStatusMark);
            indicator.status="discharging"; verify(!indicator.hasStatusMark);
            indicator.language="pl"; compare(indicator.statusText,"Rozładowywanie");
            indicator.percent=-10; compare(indicator.level,0);
            indicator.percent=110; compare(indicator.level,100);
            indicator.percent=82;
        }
        function test_settings_click_is_not_activation() {
            const gear=findChild(compact,"settingsButton");
            const battery=findChild(compact,"compactBattery");
            wait(30);
            verify(gear.mapToItem(compact,0,0).x>=battery.mapToItem(compact,battery.width,0).x);
            mouseClick(gear); compare(configureSpy.count,1); compare(activationSpy.count,0);
            compact.configureEnabled=false;
            mouseClick(gear); compare(configureSpy.count,1); compare(activationSpy.count,0);
        }
        function test_battery_hidden_settings_remain() {
            fake.hasBattery=false;
            verify(!findChild(compact,"compactBattery").visible);
            verify(findChild(compact,"settingsButton").visible);
            mouseClick(findChild(compact,"settingsButton")); compare(configureSpy.count,1);
        }
        function test_settings_hidden_when_collapsed() {
            compact.expandedHeader=false;
            verify(!findChild(compact,"settingsButton").visible);
            mouseClick(findChild(compact,"compactTitle")); compare(activationSpy.count,1);
        }
        function test_low_battery_color() {
            indicator.percent=20; compare(indicator.levelColor.toString(),"#ff9494");
            indicator.status="charging"; compare(indicator.levelColor.toString(),"#ff9494");
            indicator.percent=21; compare(indicator.levelColor.toString(),"#a7e7b8");
            indicator.percent=82;
        }
        function test_background_still_opens() {
            mouseClick(findChild(compact,"compactTitle")); compare(activationSpy.count,1);
        }
    }
}
