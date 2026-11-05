import QtQuick

Item {
    id: scheduler
    visible: false
    property var events: []
    property int leadMinutes: 15
    property string stateJson: "{}"
    property date currentTime: new Date()
    property bool autoTick: true
    property var pending: ({})
    signal reminder(var event, string phase, string key)
    signal stateEdited(string json)
    function savedState() {
        try { const value=JSON.parse(stateJson); return value && typeof value === "object" && !Array.isArray(value) ? value : {}; }
        catch (error) { return {}; }
    }
    function identity(event, start) {
        return JSON.stringify([event.sourceKey || event.calendarId || "", event.uid || event.eventUid || event.title || "", start]);
    }
    function evaluate() {
        if (!enabled) return;
        const now=currentTime.getTime(), seen=savedState();
        Object.keys(pending).forEach(key => { if (now-pending[key].at>86400000) delete pending[key]; });
        for (const event of events) {
            if (event.isAllDay) continue;
            const start=new Date(event.startDateTime).getTime();
            if (!isFinite(start)) continue;
            const phase=now>=start && now<start+120000 ? "start" : leadMinutes>0 && now>=start-leadMinutes*60000 && now<start ? "before" : "";
            if (!phase) continue;
            const key=identity(event,start)+":"+phase;
            if (Object.prototype.hasOwnProperty.call(seen,key)) continue;
            if (pending[key] && now-pending[key].at<30000) continue;
            pending[key]={at:now,start:start};
            seen[key]=start;
            reminder(event,phase,key);
        }
    }
    function acknowledge(key) {
        if (!pending[key]) return;
        const seen=savedState(); seen[key]=pending[key].start;
        delete pending[key];
        const cutoff=currentTime.getTime()-7*86400000;
        const compact={};
        // Never evict an occurrence still inside the firing window, even if a
        // large calendar produces more than the normal journal limit at once.
        Object.keys(seen).filter(k=>Number(seen[k])>=cutoff).sort((a,b)=>Number(seen[b])-Number(seen[a])).forEach(k=>{
            if (Number(seen[k])>=currentTime.getTime()-120000 || Object.keys(compact).length<512) compact[k]=seen[k];
        });
        stateEdited(JSON.stringify(compact));
    }
    onEventsChanged: Qt.callLater(evaluate)
    onCurrentTimeChanged: evaluate()
    onLeadMinutesChanged: Qt.callLater(evaluate)
    onEnabledChanged: if (enabled) Qt.callLater(evaluate)
    Timer { interval: 10000; running: scheduler.enabled && scheduler.autoTick; repeat: true; onTriggered: scheduler.currentTime=new Date() }
    Component.onCompleted: Qt.callLater(evaluate)
}
