import QtQuick
import org.kde.plasma.workspace.calendar as PlasmaCalendar
Item {
    id: backend
    property date selectedDate: new Date()
    property var events: []
    property bool providerAvailable: false
    property bool ready: false
    readonly property string errorMessage: calendar.errorMessage
    PlasmaCalendar.EventPluginsManager { id: plugins }
    PlasmaCalendar.Calendar {
        id: calendar
        days: 7; weeks: 6
        firstDayOfWeek: Qt.locale().firstDayOfWeek
        today: new Date()
        displayedDate: backend.selectedDate
    }
    function refreshAgenda() {
        if (!ready) return;
        // Plasma 6.6 only invalidates its cached agenda for today's dataReady.
        // Read a different date first so late results for another month are visible.
        calendar.daysModel.eventsForDate(new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() - 1, 12));
        // KDE handles recurrence, timezone conversion and multi-day incidences.
        events = calendar.daysModel.eventsForDate(selectedDate);
    }
    function moveDay(offset) {
        selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + offset, 12);
    }
    function resetToday() { selectedDate = new Date(); }
    function reload() { calendar.daysModel.update(); Qt.callLater(refreshAgenda); }
    onSelectedDateChanged: Qt.callLater(refreshAgenda)
    Connections {
        target: calendar.daysModel
        function onAgendaUpdated() { Qt.callLater(backend.refreshAgenda); }
    }
    Component.onCompleted: {
        // Discover by metadata ID; do not assume a distro-specific library path.
        for (var row = 0; row < plugins.model.rowCount(); ++row) {
            var pluginId = plugins.model.get(row, "pluginId");
            if (pluginId === "pimevents") {
                providerAvailable = true;
                plugins.enabledPlugins = [pluginId];
                break;
            }
        }
        calendar.daysModel.setPluginsManager(plugins);
        ready = true;
        // setPluginsManager already queues the initial load.
        Qt.callLater(refreshAgenda);
    }
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: {
            var oldToday = calendar.today;
            var now = new Date();
            var wasToday = backend.selectedDate.toDateString() === oldToday.toDateString();
            calendar.today = now;
            if (wasToday && oldToday.toDateString() !== now.toDateString()) backend.resetToday();
        }
    }
}
