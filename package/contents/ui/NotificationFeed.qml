import QtQuick

Item {
    id: feed
    visible: false
    property bool initialized: false
    property var known: ({})
    property alias duration: queue.duration
    property alias previewsEnabled: queue.enabled
    readonly property alias preview: queue.current
    NotificationQueue { id: queue }
    function sync(notes) {
        const next = {};
        for (const note of notes) {
            const revision = note.summary + "\n" + note.body + "\n" + note.updated;
            next[note.id] = revision;
            if (!initialized || known[note.id] === revision || !note.allowed) continue;
            // Expiry in KDE does not cancel the independent four-second preview.
            if (Object.prototype.hasOwnProperty.call(known, note.id)) queue.update(note);
            else queue.push(note);
        }
        known = next;
        queue.retain(notes.map(note => note.id));
        initialized = true;
    }
    function removed(id) { queue.retain(Object.keys(known).filter(key => key !== String(id))); }
    function reset() { queue.reset(); }
}
