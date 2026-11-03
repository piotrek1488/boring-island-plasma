import QtQuick
import QtTest
import "../package/contents/ui" as UI
import "../package/contents/code/Shelf.js" as Shelf
Item {
    width: 480; height: 320
    QtObject {
        id: fake
        property bool available: true
        property bool playing: false
        property string title: "Midnight City"
        property string artist: "M83 · Hurry Up, We're Dreaming"
        property string artwork: ""
        property string identity: "Test MPRIS player"
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canSeek: true
        property real duration: 240000000
        property real position: 60000000
        property real volume: 0.5
        property bool hasBattery: true
        property int percent: 82
        property bool charging: false
        property int nextCalls: 0
        property int previousCalls: 0
        function toggle() { playing = !playing; }
        function next() { nextCalls++; }
        function previous() { previousCalls++; }
        function seek(value) { position = value; }
        function setVolume(value) { volume = value; }
    }
    UI.IslandView { id: island; x: 20; y: 10; width: 440; height: 286; backend: fake; onShelfEdited: urls => shelf = urls }
    SignalSpy { id: closeSpy; target: island; signalName: "closeRequested" }
    TestCase {
        name: "Island"; when: windowShown
        function test_controls() {
            mouseClick(findChild(island, "playButton")); compare(fake.playing, true);
            mouseClick(findChild(island, "nextButton")); compare(fake.nextCalls, 1);
            mouseClick(findChild(island, "previousButton")); compare(fake.previousCalls, 1);
            fake.canNext = false;
            mouseClick(findChild(island, "nextButton")); compare(fake.nextCalls, 1);
        }
        function test_shelf() {
            island.addFiles(["file:///tmp/report.pdf", "file:///tmp/report.pdf", "https://example.com", "javascript:alert(1)"]);
            compare(island.shelf.length, 1); compare(island.page, 1);
            compare(Shelf.decode(JSON.stringify(island.shelf))[0], "file:///tmp/report.pdf");
            compare(Shelf.decode("broken").length, 0);
            compare(Shelf.decode('{"x":1}').length, 0);
            compare(Shelf.name("file:///tmp/hello%20world.pdf"), "hello world.pdf");
            var files = []; for (var i = 0; i < 30; i++) files.push("file:///tmp/" + i);
            compare(Shelf.merge([], files).length, 24);
        }
        function test_time() { compare(island.timeLabel(125000000), "2:05"); compare(island.timeLabel(-1), "0:00"); }
        function test_shapes_and_render() {
            island.page = 0; fake.canNext = true; island.forceActiveFocus();
            island.notch = false; wait(100);
            grabImage(island).save(Qt.resolvedUrl("../docs/dynamic-island.png").toString().replace("file://", ""));
            island.notch = true; wait(100);
            grabImage(island).save(Qt.resolvedUrl("../docs/notch.png").toString().replace("file://", ""));
        }
    }
}
