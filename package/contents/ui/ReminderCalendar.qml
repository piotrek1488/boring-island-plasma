import QtQuick

Item {
    id: calendar
    visible: false
    property string mode: "kde"
    property string sources: ""
    property int appletId: 0
    readonly property var events: provider.item ? provider.item.reminderEvents : []
    function load() {
        if (!enabled) return;
        provider.source="";
        provider.setSource(mode === "ics" ? "IcsCalendarBackend.qml" : "CalendarBackend.qml",
            mode === "ics" ? {appletId:appletId, sources:sources, reminderMode:true} : {reminderMode:true});
    }
    onModeChanged: Qt.callLater(load)
    onSourcesChanged: Qt.callLater(load)
    onAppletIdChanged: Qt.callLater(load)
    onEnabledChanged: { if (enabled) Qt.callLater(load); else provider.source=""; }
    Loader { id: provider; active: calendar.enabled }
    Component.onCompleted: load()
}
