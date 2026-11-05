import QtQuick

Item {
    id: queue
    visible: false
    property int duration: 4000
    property bool enabled: true
    property var pending: []
    property var current: null
    readonly property bool active: current !== null
    function update(note) {
        if (current && current.id === note.id) current = note;
        pending = pending.map(n => n.id === note.id ? note : n);
    }
    function push(note) {
        if (!enabled) return;
        if ((current && current.id === note.id) || pending.some(n => n.id === note.id)) {
            update(note);
            return;
        }
        pending = pending.concat([note]).slice(-20);
        if (!current) next();
    }
    function next() {
        timeout.stop();
        current = pending.length ? pending[0] : null;
        pending = pending.slice(1);
        if (current) timeout.restart();
    }
    function retain(ids) {
        pending = pending.filter(n => ids.indexOf(n.id) !== -1);
        if (current && ids.indexOf(current.id) === -1) next();
    }
    function reset() { pending = []; current = null; timeout.stop(); }
    onEnabledChanged: if (!enabled) reset()
    onDurationChanged: if (active) timeout.restart()
    Timer { id: timeout; interval: Math.max(1000, queue.duration); onTriggered: queue.next() }
}
