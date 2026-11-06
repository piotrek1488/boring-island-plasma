import QtQuick
import QtTest
import "../../package/contents/ui" as UI

Item {
    UI.NativeServices {
        id: bridge
        onProgressReceived: (icon,value,maximum,description) => state.progress(icon,value,maximum,description)
        onTextReceived: (icon,description) => state.text(icon,description)
    }
    UI.OsdState { id: state; enabled: bridge.osdEnabled; duration: 200 }
    SignalSpy { id: updates; target: bridge; signalName: "progressReceived" }
    TestCase {
        name: "NativeBrightnessOsd"; when: windowShown
        function init() {
            bridge.osdEnabled=true;
            tryCompare(bridge,"brightnessAvailable",true,3000);
            brightnessFixture.change("display0",400); brightnessFixture.change("display1",100);
            wait(50); state.dismiss(); updates.clear();
        }
        function test_initial_values_do_not_show_a_bar() {
            bridge.osdEnabled=false; updates.clear(); bridge.osdEnabled=true;
            tryCompare(bridge,"brightnessAvailable",true,3000); wait(30);
            compare(updates.count,0); compare(state.current,null);
        }
        function test_slider_without_plasma_osd() {
            brightnessFixture.change("display0",750);
            tryVerify(() => state.current!==null);
            compare(state.current.kind,"brightness"); compare(state.current.value,75); compare(state.current.description,"Laptop");
            compare(brightnessFixture.writeCalls(),0);
            tryCompare(state,"current",null,600);
        }
        function test_multiple_monitors_with_text_only_osd() {
            osdFixture.multipleDisplays();
            brightnessFixture.change("display0",250);
            brightnessFixture.change("display1",60);
            tryCompare(updates,"count",2,1000);
            const values=updates.signalArguments.map(args=>args[1]).sort();
            compare(JSON.stringify(values),"[25,30]");
            compare(state.current.kind,"brightness");
            compare(brightnessFixture.writeCalls(),0);
        }
        function test_volume_still_uses_plasma_osd() {
            osdFixture.volume(52); tryVerify(() => state.current!==null);
            compare(state.current.kind,"volume"); compare(state.current.value,52);
        }
        function test_disabled_and_reenabled_are_silent() {
            bridge.osdEnabled=false; compare(state.current,null);
            brightnessFixture.change("display0",900); wait(30); compare(state.current,null);
            bridge.osdEnabled=true; tryCompare(bridge,"brightnessAvailable",true,3000);
            wait(30); compare(state.current,null);
            brightnessFixture.change("display0",910); tryVerify(() => state.current!==null);
            compare(state.current.value,91); compare(brightnessFixture.writeCalls(),0);
        }
    }
}
