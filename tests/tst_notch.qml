import QtQuick
import QtTest
import "../package/contents/ui" as UI

Item {
    width: 600; height: 300
    UI.LowBatteryMonitor { id: monitor; duration: 100 }
    SignalSpy { id: warnings; target: monitor; signalName: "warning" }
    UI.IslandSurface { id: surface; x: 300; width: 240; height: 80; notch: true }
    Item {
        id: panel; width: 280; height: 80
        Item {
            id: padding; x: 20; y: 12; width: 240; height: 32; clip: true
            UI.CompactView {
                id: compact; width: 240; height: 32
                backend: QtObject {
                    property bool hasBattery: false
                    property int percent: 100
                    property bool playing: false
                    property string title: "Fixture"
                }
                panelItem: panel; notch: true; autoHeight: false; compactHeight: 60
            }
        }
    }
    TestCase {
        name: "NotchAndLowBattery"; when: windowShown
        function init() {
            monitor.hasBattery=false; monitor.powered=false; monitor.percent=100;
            wait(10); warnings.clear();
        }
        function test_low_battery_once_per_discharge() {
            monitor.hasBattery=true; monitor.percent=21; wait(10); compare(warnings.count,0);
            monitor.percent=20; tryCompare(warnings,"count",1); verify(monitor.active);
            monitor.percent=19; wait(20); compare(warnings.count,1);
            tryCompare(monitor,"active",false,250);
            monitor.percent=18; wait(20); compare(warnings.count,1);
            monitor.powered=true; wait(10);
            monitor.powered=false; tryCompare(warnings,"count",2);
            monitor.dismiss(); verify(!monitor.active);
            monitor.percent=22; wait(10);
            monitor.percent=20; tryCompare(warnings,"count",3);
        }
        function test_charging_does_not_warn() {
            monitor.powered=true; monitor.hasBattery=true; monitor.percent=10;
            wait(30); compare(warnings.count,0); verify(!monitor.active);
        }
        function test_panel_height_and_ancestor_movement() {
            compare(compact.height,32); compare(compact.visualItem.height,60);
            compare(compact.visualItem.parent,panel); compare(compact.visualItem.y,0);
            padding.x=30; tryCompare(compact.visualItem,"x",30);
            compact.compactScale=0.5; compare(compact.visualItem.height,30);
            compact.compactScale=1; padding.x=20;
            compact.autoHeight=true; compare(compact.effectiveHeight,80);
            compact.autoHeight=false;
        }
        function test_concave_shoulders_data() {
            return [{tag:"compact",h:42},{tag:"expanded",h:240}];
        }
        function test_concave_shoulders(data) {
            surface.height=data.h; surface.notch=true; wait(60);
            const image=grabImage(surface);
            compare(image.red(9,7),9);
            verify(image.red(6,0)<100);
            verify(image.red(0,7)>100);
            compare(image.red(9,7),9);
            verify(image.red(239,7)>100);
            compare(image.red(230,7),9);
            surface.notch=false; compare(surface.shoulder,0);
        }
    }
}
