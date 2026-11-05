import QtQuick
import QtQuick.Controls
import QtTest
import "../../package/contents/ui" as UI

Item {
    width: 800; height: 700
    UI.ConfigGeneral { id: config; width: 640; height: 360 }
    UI.UpdateBackend { id: reader }
    QtObject {
        id: mock
        property string installedVersion: "1.0.0"
        property string latestVersion: "1.1.0"
        property string state: "idle"
        property string errorMessage: ""
        property bool busy: false
        property int checks: 0
        property int installs: 0
        property int restarts: 0
        function check() { checks++; state="available"; }
        function install() { installs++; state="installed"; }
        function restart() { restarts++; busy=true; state="restarting"; }
    }
    UI.ConfigAbout { id: about; width: 460; height: 400; backend: mock; visible: false }
    TestCase {
        name: "ScrollableSettings"; when: windowShown
        function init() { config.visible=true; about.visible=false; mock.state="idle"; mock.busy=false; mock.checks=0; mock.installs=0; mock.restarts=0; }
        function test_reset_is_reachable_data() {
            return [{tag:"english",language:"en",width:640,height:360}, {tag:"polish-small",language:"pl",width:460,height:240}];
        }
        function test_reset_is_reachable(data) {
            config.width=data.width; config.height=data.height;
            config.cfg_language=data.language; config.cfg_calendarMode="ics";
            config.cfg_idleView="date"; config.cfg_animationDuration=600;
            const flick=config.contentItem, reset=findChild(config,"resetDefaultsButton");
            tryVerify(() => flick.contentHeight>config.height);
            verify(waitForRendering(config));
            compare(config.ScrollBar.horizontal.policy,ScrollBar.AlwaysOff);
            compare(config.ScrollBar.vertical.policy,ScrollBar.AlwaysOn);
            flick.contentY=flick.contentHeight-flick.height;
            verify(waitForRendering(config));
            const p=reset.mapToItem(config,0,0);
            verify(p.y>=0 && p.y+reset.height<=config.height+1, "reset="+p.y+" height="+reset.height+" viewport="+config.height+" content="+flick.contentHeight+" scroll="+flick.contentY);
            mouseClick(reset);
            compare(config.cfg_idleView,"clock"); compare(config.cfg_animationDuration,400);
        }
        function test_idle_selection() {
            config.cfg_idleView="date";
            const choice=findChild(config,"idleViewSetting");
            compare(choice.currentIndex,2);
            choice.activated(3); compare(config.cfg_idleView,"battery");
            choice.activated(2); compare(config.cfg_idleView,"date");
        }
        function test_about_update_actions() {
            config.visible=false; about.visible=true; about.cfg_language="pl";
            const check=findChild(about,"checkUpdatesButton"), install=findChild(about,"installUpdateButton"), restart=findChild(about,"restartPlasmaButton");
            verify(waitForRendering(about));
            verify(!install.visible); verify(!restart.visible);
            mouseClick(check); compare(mock.checks,1);
            verify(install.visible); verify(waitForRendering(about));
            mouseClick(install); compare(mock.installs,1); verify(restart.visible);
            verify(!check.enabled); verify(waitForRendering(about));
            mouseClick(restart); compare(mock.restarts,1); verify(!restart.enabled);
        }
        function test_native_version_reader() {
            tryVerify(() => !reader.busy && reader.installedVersion.length>0,5000);
            verify(/^\d+\.\d+\.\d+$/.test(reader.installedVersion)); compare(reader.errorMessage,"");
        }
    }
}
