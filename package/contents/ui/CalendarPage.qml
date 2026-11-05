pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: agenda
    objectName: "calendarPage"
    property string language: "en"
    Translations { id: strings; language: agenda.language }
    property string calendarMode: "kde"
    property string calendarSources: ""
    property int calendarAppletId: 0
    property var backend: null
    readonly property var activeBackend: backend || calendarLoader.item || fallback
    QtObject {
        id: fallback
        property date selectedDate: new Date()
        property var events: []
        property var eventDays: ({})
        property bool providerAvailable: true
        property string errorMessage: "Loading calendar…"
        function moveDay(offset) {}
        function resetToday() {}
        function reload() {}
    }
    Loader {
        id: calendarLoader
        active: agenda.backend === null
        source: active ? (agenda.calendarMode === "ics" ? "IcsCalendarBackend.qml" : "CalendarBackend.qml") : ""
        onLoaded: if (agenda.calendarMode === "ics") {
            item.appletId = Qt.binding(() => agenda.calendarAppletId);
            item.sources = Qt.binding(() => agenda.calendarSources);
        }
    }
    spacing: 0
    RowLayout {
        Layout.fillWidth: true; Layout.fillHeight: true
        spacing: 12
        ColumnLayout {
            id: eventsPane
            objectName: "calendarEventsPane"
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.minimumWidth: 0
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: agenda.activeBackend.selectedDate.toLocaleDateString(strings.locale, "ddd, d MMM yyyy")
                    color: "#eeeaf8"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight
                }
                ActionButton {
                    objectName: "refreshCalendar"; text: "↻"; implicitWidth: 26; implicitHeight: 26; leftPadding: 2; rightPadding: 2
                    Accessible.description: strings.text("Refresh calendar"); onClicked: agenda.activeBackend.reload()
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                ActionButton { objectName: "previousDay"; text: "‹"; implicitWidth: 26; implicitHeight: 24; leftPadding: 2; rightPadding: 2; Accessible.description: strings.text("Previous day"); onClicked: agenda.activeBackend.moveDay(-1) }
                ActionButton { objectName: "todayButton"; text: strings.text("Today"); implicitHeight: 24; textSize: 11; onClicked: agenda.activeBackend.resetToday() }
                ActionButton { objectName: "nextDay"; text: "›"; implicitWidth: 26; implicitHeight: 24; leftPadding: 2; rightPadding: 2; Accessible.description: strings.text("Next day"); onClicked: agenda.activeBackend.moveDay(1) }
                Item { Layout.fillWidth: true }
            }
            ScrollView {
                id: statusScroll
                visible: !agenda.activeBackend.providerAvailable || agenda.activeBackend.errorMessage.length > 0 || agenda.activeBackend.events.length === 0
                Layout.fillWidth: true; Layout.fillHeight: agenda.activeBackend.events.length === 0
                Layout.preferredHeight: Math.min(statusText.implicitHeight + 6, eventsPane.height / 3)
                clip: true; contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                Text {
                    id: statusText
                    objectName: "calendarStatus"
                    width: statusScroll.availableWidth
                    wrapMode: Text.WordWrap; textFormat: Text.PlainText; color: "#aaa9bb"; font.pixelSize: 11
                    text: agenda.activeBackend.errorMessage ? strings.text(agenda.activeBackend.errorMessage) : !agenda.activeBackend.providerAvailable
                        ? strings.text("KDE PIM calendar integration is not installed. Install the PIM Events plugin (kdepim-addons on Ubuntu), then restart this widget. Select calendars in the Plasma clock settings → Calendar → PIM Events.")
                        : agenda.calendarMode === "ics" ? strings.text("No events for this day.") : strings.text("No events for this day. Calendar sources are shared with Plasma: select your Akonadi calendars in the clock settings → Calendar → PIM Events. Accounts are managed in KOrganizer.")
                }
            }
            ListView {
                id: eventList
                objectName: "eventList"
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 0
                clip: true; spacing: 5
                visible: agenda.activeBackend.events.length > 0
                model: agenda.activeBackend.events
                ScrollBar.vertical: ScrollBar {}
                delegate: Rectangle {
                    id: eventRow
                    required property var modelData
                    width: eventList.width - 10; height: 48; radius: 8; color: "#20212a"
                    Rectangle { x: 0; y: 7; width: 3; height: parent.height - 14; radius: 2; color: eventRow.modelData.eventColor || "#c4b5fd" }
                    Column {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; anchors.topMargin: 6; spacing: 3
                        Text { width: parent.width; text: eventRow.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: "#eeeaf8"; font.pixelSize: 12 }
                        Text { width: parent.width; elide: Text.ElideRight; text: eventRow.modelData.isAllDay ? strings.text("All day") : Qt.formatTime(eventRow.modelData.startDateTime, "hh:mm") + " – " + Qt.formatTime(eventRow.modelData.endDateTime, "hh:mm"); color: "#aaa9bb"; font.pixelSize: 10 }
                    }
                    HoverHandler { id: eventHover }
                    ToolTip.visible: eventHover.hovered
                    ToolTip.text: modelData.title + (modelData.description ? "\n" + modelData.description : "")
                }
            }
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: "#272831" }
        CalendarMonth {
            objectName: "calendarMonthPane"
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.minimumWidth: 0
            language: agenda.language
            selectedDate: agenda.activeBackend.selectedDate
            eventDays: agenda.activeBackend.eventDays || ({})
            onDateSelected: value => agenda.activeBackend.selectedDate = value
        }
    }
}
