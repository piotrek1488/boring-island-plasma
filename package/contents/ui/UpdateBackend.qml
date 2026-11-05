import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: updater
    visible: false
    property string installedVersion: ""
    property string latestVersion: ""
    property string state: "idle"
    property string errorMessage: ""
    property string command: ""
    readonly property bool busy: command !== ""
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("../code/update.py").toString().replace(/^file:\/\//, ""))
    function quote(value) { return "'" + String(value).replace(/'/g, "'\\''") + "'"; }
    function run(action) {
        if (busy) return;
        errorMessage = "";
        state = action === "check" ? "checking" : action === "install" ? "installing" : action === "restart" ? "restarting" : "idle";
        command = "python3 " + quote(script) + " --action " + quote(action)
            + (action === "install" ? " --version " + quote(latestVersion) : "");
        executor.connectSource(command);
    }
    function check() { run("check"); }
    function install() { if (state === "available") run("install"); }
    function restart() { if (state === "installed") run("restart"); }
    Plasma5Support.DataSource {
        id: executor
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            updater.command = "";
            try {
                const result = JSON.parse(data.stdout);
                if (data["exit code"] !== 0 || !result.status) throw new Error();
                if (result.installed) updater.installedVersion = result.installed;
                if (result.latest) updater.latestVersion = result.latest;
                updater.state = result.status;
                updater.errorMessage = result.message || "";
            } catch (error) {
                updater.state = "error";
                updater.errorMessage = "Update operation failed.";
            }
        }
    }
    Component.onCompleted: run("info")
}
