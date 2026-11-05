import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: backend
    property int appletId: 0
    property string sources: ""
    property date selectedDate: new Date()
    property var events: []
    readonly property bool providerAvailable: true
    property string errorMessage: "Loading calendar…"
    property string currentCommand: ""
    property int serial: 0
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("../code/calendar_ics.py").toString().replace(/^file:\/\//, ""))
    function quote(value) { return "'" + String(value).replace(/'/g, "'\\''") + "'"; }
    function reload(force = true) {
        if (!appletId) return;
        const day = Qt.formatDate(selectedDate, "yyyy-MM-dd");
        // Use the optional dedicated venv, otherwise try system Python. Feed URLs
        // are read from the saved applet configuration, not exposed in argv.
        const launch = 'calendar_python="${XDG_DATA_HOME:-$HOME/.local/share}/boring-island/calendar-venv/bin/python"; '
            + 'if [ ! -x "$calendar_python" ]; then calendar_python=python3; fi; "$calendar_python" ';
        currentCommand = launch + quote(script) + " --applet-id " + appletId + " --date " + day + (force ? " --refresh" : "") + " # " + (++serial);
        errorMessage = "Loading calendar…";
        collector.connectSource(currentCommand);
    }
    function moveDay(offset) { selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + offset, 12); }
    function resetToday() { selectedDate = new Date(); }
    onSelectedDateChanged: debounce.restart()
    onSourcesChanged: { debounce.restart(); syncRetry.remaining = 4; syncRetry.restart(); }
    onAppletIdChanged: debounce.restart()
    Plasma5Support.DataSource {
        id: collector
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source !== backend.currentCommand) return;
            try {
                if (data["exit code"] !== 0) throw new Error("calendar");
                const result = JSON.parse(data.stdout);
                backend.events = result.events.map(event => Object.assign({}, event, {
                    startDateTime: new Date(event.startDateTime), endDateTime: new Date(event.endDateTime)
                }));
                backend.errorMessage = result.error || "";
            } catch (error) { backend.events = []; backend.errorMessage = "Calendar data could not be loaded."; }
        }
    }
    // KConfig may flush an Apply asynchronously. Retry briefly without putting
    // private feed addresses in the executable engine command.
    Timer {
        id: syncRetry; interval: 3000; repeat: true
        property int remaining: 4
        onTriggered: { backend.reload(false); if (--remaining <= 0) stop(); }
    }
    Timer { id: debounce; interval: 1000; onTriggered: backend.reload(false) }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: backend.reload(false) }
    Timer {
        interval: 60000; running: true; repeat: true
        property date previousToday: new Date()
        onTriggered: {
            const now = new Date();
            if (backend.selectedDate.toDateString() === previousToday.toDateString() && previousToday.toDateString() !== now.toDateString()) backend.resetToday();
            previousToday = now;
        }
    }
    Component.onCompleted: { debounce.restart(); syncRetry.restart(); }
}
