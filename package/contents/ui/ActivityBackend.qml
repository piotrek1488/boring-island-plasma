import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: backend
    visible: false
    property bool systemEnabled: true
    property bool packagesEnabled: true
    property bool llmEnabled: false
    property bool audioEnabled: true
    property var snapshot: ({})
    property string error: ""
    property double lastUpdate: 0
    readonly property var system: snapshot.system || ({})
    readonly property var packages: snapshot.packages || ({active: false})
    readonly property var llm: snapshot.llm || ({active: false})
    readonly property string audio: snapshot.audio || ""
    readonly property string features: [systemEnabled ? "system" : "", packagesEnabled ? "packages" : "", llmEnabled ? "llm" : "", audioEnabled ? "audio" : ""].filter(Boolean).join(",")
    readonly property string scriptPath: decodeURIComponent(Qt.resolvedUrl("../code/collect.py").toString().replace(/^file:\/\//, ""))
    function quote(s) { return "'" + s.replace(/'/g, "'\\''") + "'"; }
    readonly property string collectCommand: "python3 " + quote(scriptPath) + " --features " + quote(features)
    function open(kind) {
        if (["system", "packages", "llm"].indexOf(kind) !== -1)
            launcher.connectSource("python3 " + quote(scriptPath) + " --open " + kind);
    }
    onFeaturesChanged: { snapshot = {}; lastUpdate = 0; }
    Plasma5Support.DataSource {
        id: collector
        engine: "executable"
        connectedSources: backend.features ? [backend.collectCommand] : []
        interval: 3000
        onNewData: (source, data) => {
            try {
                if (data["exit code"] !== 0) throw new Error("collector");
                backend.snapshot = JSON.parse(data.stdout);
                backend.lastUpdate = Date.now();
                backend.error = "";
            } catch (e) { backend.snapshot = {}; backend.error = "Activity data unavailable"; }
        }
    }
    Plasma5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: (source, data) => disconnectSource(source)
    }
    Timer {
        interval: 5000; running: backend.features !== ""; repeat: true
        onTriggered: if (backend.lastUpdate && Date.now() - backend.lastUpdate > 15000) { backend.snapshot = {}; backend.error = "Activity data unavailable"; }
    }
}
