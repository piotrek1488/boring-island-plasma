import QtQuick
import QtTest
import "../package/contents/code/SettingsDefaults.js" as Defaults
import "../package/contents/ui" as UI
Item {
    width: 420; height: 180
    QtObject {
        id: fake
        property string title: "A long track title for a narrow panel"
        property bool playing: true
        property bool hasBattery: true
        property bool charging: false
        property int percent: 82
    }
    UI.CompactView { id: compact; width: 240; height: 64; backend: fake }
    UI.ConfigGeneral { id: settings; visible: false }
    SignalSpy { id: activation; target: compact; signalName: "activated" }
    TestCase {
        name: "CompactSizing"; when: windowShown
        function init() {
            compact.compactScale=1; compact.autoHeight = true; compact.compactHeight = 42;
            compact.notch = false; compact.height = 64;
            activation.clear();
        }
        function test_auto_data() {
            return [16, 24, 32, 42, 48, 64, 96, 128].map(h => ({tag: "panel-" + h, h: h}));
        }
        function test_auto(data) {
            compact.height = data.h;
            compare(findChild(compact, "compactVisual").height, data.h);
            verify(compact.contentScale > 0);
            compare(compact.width, 240);
        }
        function test_manual_clamping_and_alignment() {
            compact.autoHeight = false; compact.compactHeight = 32;
            var visual = findChild(compact, "compactVisual");
            compare(visual.height, 32); compare(visual.y, 16);
            compact.notch = true; compare(visual.y, 0);
            compact.compactHeight = 128; compare(visual.height, 128);
            compact.height = 24; compare(visual.height, 128);
            compact.autoHeight = true; compact.height = 48;
            compare(visual.height, 48);
        }
        function test_hit_area_follows_shape() {
            compact.autoHeight = false; compact.compactHeight = 24;
            mouseClick(compact, 120, 3); compare(activation.count, 0);
            mouseClick(compact, 120, 32); compare(activation.count, 1);
            compact.notch = true;
            mouseClick(compact, 120, 50); compare(activation.count, 1);
            mouseClick(compact, 120, 12); compare(activation.count, 2);
        }
        function test_compact_scale() {
            compact.autoHeight=true; compact.height=64; compact.compactScale=0.5;
            compare(compact.effectiveHeight,32);
            compact.compactScale=2; compare(compact.effectiveHeight,128);
            compact.autoHeight=false; compact.compactHeight=20; compact.compactScale=1.5;
            compare(compact.effectiveHeight,30);
        }
        function test_reset_settings_button() {
            settings.cfg_language="pl"; settings.cfg_shape=0;
            settings.cfg_animationDuration=50; settings.cfg_hoverOpen=false;
            settings.restoreDefaults();
            for (const name in Defaults.values) compare(settings["cfg_"+name],Defaults.values[name]);
            compare(findChild(settings,"resetDefaultsButton").text,"Restore default settings");
        }
        function test_settings() {
            settings.cfg_autoHeight = true;
            verify(findChild(settings, "compactHeightSetting").enabled);
            settings.cfg_autoHeight = false;
            verify(findChild(settings, "compactHeightSetting").enabled);
            settings.cfg_compactHeight = 54;
            compare(findChild(settings, "compactHeightSetting").value, 54);
        }
    }
}
