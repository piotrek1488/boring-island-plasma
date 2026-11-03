import QtQuick
import QtTest
import "../package/contents/ui" as UI
Item {
    UI.SystemBackend { id: backend }
    TestCase {
        name: "MprisProtocol"; when: windowShown
        function test_protocol() {
            tryCompare(backend, "available", true, 5000);
            tryCompare(backend, "title", "Protocol test");
            compare(backend.duration, 180000000);
            compare(backend.playing, false);
            backend.toggle(); tryCompare(backend, "playing", true);
            backend.next(); tryCompare(backend, "title", "Next track");
            backend.previous(); tryCompare(backend, "title", "Previous track");
            backend.seek(60000000); tryCompare(backend, "position", 60000000);
            backend.setVolume(0.8); tryCompare(backend, "volume", 0.8);
            backend.setVolume(2); tryCompare(backend, "volume", 1);
            backend.seek(-100); tryCompare(backend, "position", 0);
        }
    }
}
