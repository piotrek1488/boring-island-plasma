import QtQuick
import QtQuick.Window
import QtTest
import "../../package/contents/ui" as UI

Item {
    id: fixture
    width: 1000; height: 800
    property bool opened: false
    property bool ready: false
    QtObject {
        id: media
        property bool available: false
        property bool playing: false
        property string title: ""
        property string artist: ""
        property string artwork: ""
        property string identity: ""
        property bool canToggle: false
        property bool canPrevious: false
        property bool canNext: false
        property bool canSeek: false
        property real duration: 0
        property real position: 0
        property real volume: 1
        property bool hasBattery: true
        property int percent: 80
        property string batteryStatus: "discharging"
    }
    UI.NotificationBackend { id: notifications }
    UI.CompactView {
        id: compact
        width: 240; height: 42
        backend: media
        panelItem: fixture.Window.window ? fixture.Window.window.contentItem : null
        opacity: popup.visible ? 0 : 1
        onHoverChanged: hovered => { if (hovered) fixture.opened = true; }
    }
    UI.AttachedDialog {
        id: popup
        visible: fixture.opened || shell.progress > 0.001
        transientParent: fixture.Window.window
        onVisibleChanged: {
            x=80; y=48;
            fixture.ready=visible;
        }
        mainItem: UI.ExpandingIsland {
            id: shell
            backend: media; notifications: notifications; activities: null
            fixedViewport: true
            opened: fixture.ready && fixture.opened
            fullView: fixture.opened
            displayText: "18:20"
        }
    }
    TestCase {
        name: "ExpandingPopup"
        when: windowShown
        function cleanup() { fixture.opened=false; tryCompare(shell,"progress",0,1000); }
        function test_open_close_repeatedly_data() {
            return [{tag:"smooth-island",style:"smooth",notch:false},
                {tag:"smooth-notch",style:"smooth",notch:true},
                {tag:"spring-notch",style:"spring",notch:true}];
        }
        function test_open_close_repeatedly(data) {
            shell.animationStyle=data.style; shell.notch=data.notch;
            for (let i=0;i<5;i++) {
                fixture.opened=true;
                tryCompare(shell,"progress",1,1000);
                verify(popup.visible);
                fixture.opened=false;
                tryCompare(shell,"progress",0,1000);
                tryCompare(popup,"visible",false);
            }
        }
    }
}
