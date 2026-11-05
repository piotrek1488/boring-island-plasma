import QtQuick
import QtTest
import "../package/contents/ui" as UI

Item {
    width: 1100; height: 950
    QtObject {
        id: media
        property bool available: true
        property bool playing: false
        property string title: "Test track"
        property string artist: "Test artist"
        property string artwork: ""
        property string identity: "Fixture"
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canSeek: true
        property real duration: 100000000
        property real position: 20000000
        property real volume: 0.5
        property bool hasBattery: true
        property int percent: 80
        property bool charging: false
        function toggle() { playing = !playing; }
        function next() {}
        function previous() {}
        function seek(value) { position = value; }
        function setVolume(value) { volume = value; }
    }
    ListModel { id: historyModel }
    QtObject {
        id: notifications
        property var preview: null
        property var history: historyModel
        property int count: historyModel.count
        property bool available: true
        function clearAll() { historyModel.clear(); }
        function closeId(id) { for (let i=historyModel.count-1;i>=0;--i) if (historyModel.get(i).id === id) historyModel.remove(i); }
    }
    QtObject {
        id: activities
        property bool systemEnabled: true
        property bool packagesEnabled: true
        property bool llmEnabled: true
        property var system: ({cpu: 42, ram: 60, gpus: [{name: "Test GPU", util: 25}]})
        property var packages: ({active: false})
        property var llm: ({active: false})
        property string audio: "Test speaker"
        property string error: ""
        function open(kind) {}
    }
    UI.ExpandingIsland {
        id: shell
        backend: media; notifications: notifications; activities: activities
        onPinRequested: mode => pinnedMode = mode
    }
    TestCase {
        name: "Expansion"; when: windowShown
        function init() { shell.opened=false; shell.fullView=false; shell.reduceMotion=true; shell.notch=false; shell.uiScale=1; shell.initialPage=0; historyModel.clear(); }
        function test_shapes_and_scaling_data() {
            return [{tag:"island",notch:false},{tag:"notch",notch:true}];
        }
        function test_shapes_and_scaling(data) {
            shell.notch=data.notch; shell.fullView=true; shell.opened=true;
            compare(shell.width,520); compare(shell.height,432);
            shell.uiScale=1.5;
            compare(shell.width,780); compare(shell.height,627);
            shell.opened=false;
            compare(shell.width,240); compare(shell.height,42);
        }
        function test_animation() {
            shell.reduceMotion=false; shell.fullView=true; shell.opened=true;
            wait(90); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",1,600);
            shell.opened=false;
            wait(90); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",0,600);
        }
        function test_notification_history() {
            historyModel.append({id:"a", applicationName:"Fixture",summary:"Hello",body:"World"});
            shell.fullView=true; shell.opened=true; shell.initialPage=4;
            tryVerify(() => findChild(shell,"notificationsPage") !== null);
            compare(findChild(shell,"notificationsTab").text,"Notifications · 1");
            notifications.closeId("a");
            compare(historyModel.count,0);
            shell.language="pl";
            compare(findChild(shell,"notificationsTab").text,"Powiadomienia · 0");
            shell.language="en";
        }
        function test_activity_page() {
            shell.fullView=true; shell.opened=true; shell.initialPage=5;
            tryVerify(() => findChild(shell,"activityPage") !== null);
            verify(shell.height>400);
        }
    }
}
