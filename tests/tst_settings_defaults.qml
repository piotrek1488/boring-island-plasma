import QtQuick
import QtQuick.Controls
import QtTest
import "../package/contents/code/SettingsDefaults.js" as Defaults

Item {
    SpinBox { id: animation; from: 50; to: 1000; value: 50 }
    CheckBox { id: hover; checked: false }
    QtObject {
        id: aliasTarget
        property alias cfg_animationDuration: animation.value
        property alias cfg_hoverOpen: hover.checked
    }
    TestCase {
        name: "SettingsDefaults"; when: windowShown
        function test_reset_preserves_shelf_and_other_fields() {
            const draft = {cfg_shelfJson:'["file:///home/test/report.pdf"]', unrelated:42};
            for (const name in Defaults.values) draft["cfg_"+name]="changed";
            Defaults.restore(draft);
            for (const name in Defaults.values) compare(draft["cfg_"+name],Defaults.values[name]);
            compare(draft.cfg_shelfJson,'["file:///home/test/report.pdf"]');
            compare(draft.unrelated,42);
            Defaults.restore(draft); compare(draft.cfg_animationDuration,400);
        }
        function test_reset_writes_control_aliases() {
            // Proxy these two fields through real controls like the configuration form.
            const draft = {};
            for (const name in Defaults.values) draft["cfg_"+name]=Defaults.values[name];
            Object.defineProperty(draft,"cfg_animationDuration",{set:value=>aliasTarget.cfg_animationDuration=value});
            Object.defineProperty(draft,"cfg_hoverOpen",{set:value=>aliasTarget.cfg_hoverOpen=value});
            Defaults.restore(draft);
            compare(animation.value,400); verify(hover.checked);
        }
    }
}
