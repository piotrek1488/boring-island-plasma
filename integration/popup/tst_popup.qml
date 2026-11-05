// Requires Plasma 6. Run with scripts/test-popup.sh on the target desktop.
import QtQuick
import QtQuick.Window
import QtTest
import "../../package/contents/ui" as UI

TestCase {
    name: "AttachedPopup"
    when: windowShown
    UI.AttachedDialog {
        id: overlay
        visible: false
        mainItem: Item { width: 520; height: 446 }
    }
    function cleanup() { overlay.visible=false; overlay.keyboardRequested=false; }
    function test_hover_is_nonactivating() {
        verify(overlay.flags & Qt.WindowDoesNotAcceptFocus);
        overlay.x=80; overlay.y=48;
        overlay.visible=true;
        wait(100);
        verify(overlay.flags & Qt.WindowDoesNotAcceptFocus);
        verify(!overlay.active);
    }
    function test_show_does_not_reposition() {
        compare(overlay.visualParent,null);
        overlay.x=80; overlay.y=48;
        overlay.visible=true;
        wait(100);
        compare(overlay.x,80); compare(overlay.y,48);
        overlay.mainItem.height=500;
        wait(100);
        compare(overlay.x,80); compare(overlay.y,48);
        overlay.mainItem.height=446;
    }
    function test_keyboard_focus_is_explicit() {
        overlay.keyboardRequested=true;
        verify(!(overlay.flags & Qt.WindowDoesNotAcceptFocus));
        verify(overlay.hideOnWindowDeactivate);
    }
}
