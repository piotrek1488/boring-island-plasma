import QtQuick
import "../code/CalendarMath.js" as CalendarMath
import org.kde.plasma.workspace.calendar as PlasmaCalendar
Item {
    id: backend
    property date selectedDate: new Date()
    property var events: []
    property var eventDays: ({})
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
        // Reading each date also invalidates Plasma 6.6's cached agenda for
        // non-today dataReady updates. Read the selected date last for the list.
        const markers = {};
        const days = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, 0).getDate();
        for (let day = 1; day <= days; ++day) {
            const date = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), day, 12);
            if (calendar.daysModel.eventsForDate(date).length > 0) markers[CalendarMath.key(date)] = true;
        }
        eventDays = markers;
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
