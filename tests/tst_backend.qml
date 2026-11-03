import QtQuick
import QtTest
import "../package/contents/ui" as UI
Item {
    UI.SystemBackend { id: backend }
    TestCase {
        name: "Backend"; when: windowShown
        function test_empty_session() {
            wait(300);
            compare(backend.available, false);
            compare(backend.canToggle, false);
            compare(backend.canSeek, false);
            backend.toggle(); backend.next(); backend.previous(); backend.seek(10); backend.setVolume(1);
        }
    }
}
