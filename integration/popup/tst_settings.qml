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
        property int logins: 0
        function check() { checks++; state="available"; }
        function install() { installs++; state="installed"; }
        function restart() { restarts++; busy=true; state="restarting"; }
        function login() { logins++; }
    }
    UI.ConfigUpdates { id: updates; width: 460; height: 400; backend: mock; visible: false }
    TestCase {
        name: "ScrollableSettings"; when: windowShown
        function init() { config.visible=true; updates.visible=false; mock.state="idle"; mock.busy=false; mock.checks=0; mock.installs=0; mock.restarts=0; mock.logins=0; }
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
            flick.contentY=0;
            verify(waitForRendering(config));
            verify(findChild(config,"languageChoice").mapToItem(config,0,0).y>=20);
            compare(config.ScrollBar.horizontal.policy,ScrollBar.AlwaysOff);
            compare(config.ScrollBar.vertical.policy,ScrollBar.AlwaysOn);
            flick.contentY=flick.contentHeight-flick.height;
            verify(waitForRendering(config));
            const p=reset.mapToItem(config,0,0);
            verify(p.y>=20 && p.y+reset.height<=config.height-19, "reset="+p.y+" height="+reset.height+" viewport="+config.height+" content="+flick.contentHeight+" scroll="+flick.contentY);
            const last=findChild(config,"calendarSetupInstructions"), help=findChild(config,"resetHelp");
            verify(help.mapToItem(config,0,0).y-last.mapToItem(config,0,last.height).y>=20);
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
        function test_update_actions() {
            config.visible=false; updates.visible=true; updates.cfg_language="pl";
            const check=findChild(updates,"checkUpdatesButton"), install=findChild(updates,"installUpdateButton"), restart=findChild(updates,"restartPlasmaButton");
            verify(waitForRendering(updates));
            compare(findChild(updates,"updatesTitle").text,"Aktualizacje");
            verify(!install.visible); verify(!restart.visible);
            mouseClick(check); compare(mock.checks,1);
            verify(install.visible); verify(waitForRendering(updates));
            mouseClick(install); compare(mock.installs,1); verify(restart.visible);
            verify(!check.enabled); verify(waitForRendering(updates));
            mouseClick(restart); compare(mock.restarts,1); verify(!restart.enabled);
        }
        function test_private_release_login_button() {
            config.visible=false; updates.visible=true; mock.state="authRequired";
            mock.errorMessage="Sign in with gh auth login --hostname github.com using an account with access to this repository, then check again.";
            updates.cfg_language="pl";
            const login=findChild(updates,"githubLoginButton");
            verify(waitForRendering(updates));
            verify(login.visible); verify(findChild(updates,"checkUpdatesButton").enabled);
            verify(findChild(updates,"updateStatus").text.indexOf("gh auth login")>=0);
            mouseClick(login); compare(mock.logins,1);
            mock.errorMessage="";
        }
        function test_native_version_reader() {
            tryVerify(() => !reader.busy && reader.installedVersion.length>0,5000);
            verify(/^\d+\.\d+\.\d+$/.test(reader.installedVersion)); compare(reader.errorMessage,"");
        }
    }
}
