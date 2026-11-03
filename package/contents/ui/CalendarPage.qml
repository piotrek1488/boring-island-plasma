pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: agenda
    objectName: "calendarPage"
    property string language: "en"
    Translations { id: strings; language: agenda.language }
    property var backend: nativeBackend
    CalendarBackend { id: nativeBackend }
    spacing: 6
    RowLayout {
        ActionButton { objectName: "previousDay"; text: "‹"; implicitWidth: 30; implicitHeight: 28; Accessible.description: strings.text("Previous day"); onClicked: agenda.backend.moveDay(-1) }
        Text { Layout.fillWidth: true; text: agenda.backend.selectedDate.toLocaleDateString(strings.locale, "ddd, d MMM yyyy"); color: "#eeeaf8"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
        ActionButton { objectName: "nextDay"; text: "›"; implicitWidth: 30; implicitHeight: 28; Accessible.description: strings.text("Next day"); onClicked: agenda.backend.moveDay(1) }
        ActionButton { text: strings.text("Today"); implicitWidth: 64; implicitHeight: 28; onClicked: agenda.backend.resetToday() }
        ActionButton { text: "↻"; implicitWidth: 30; implicitHeight: 28; Accessible.description: strings.text("Refresh calendar"); onClicked: agenda.backend.reload() }
    }
    Text {
        objectName: "calendarStatus"
        visible: !agenda.backend.providerAvailable || agenda.backend.errorMessage.length > 0 || agenda.backend.events.length === 0
        Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; color: "#aaa9bb"; font.pixelSize: 12
        text: !agenda.backend.providerAvailable
            ? strings.text("KDE PIM calendar integration is not installed. Install the PIM Events plugin (kdepim-addons on Ubuntu), then restart this widget. Select calendars in the Plasma clock settings → Calendar → PIM Events.")
            : agenda.backend.errorMessage || strings.text("No events for this day. Calendar sources are shared with Plasma: select your Akonadi calendars in the clock settings → Calendar → PIM Events. Accounts are managed in KOrganizer.")
    }
    ListView {
        id: eventList
        objectName: "eventList"
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 5
        model: agenda.backend.events
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            id: eventRow
            required property var modelData
            width: ListView.view.width - 12; height: 48; radius: 8; color: "#20212a"
            Rectangle { x: 0; y: 7; width: 3; height: parent.height - 14; radius: 2; color: eventRow.modelData.eventColor || "#c4b5fd" }
            Column {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; anchors.topMargin: 6; spacing: 3
                Text { width: parent.width; text: eventRow.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: "#eeeaf8"; font.pixelSize: 13 }
                Text { text: eventRow.modelData.isAllDay ? strings.text("All day") : Qt.formatTime(eventRow.modelData.startDateTime, "hh:mm") + " – " + Qt.formatTime(eventRow.modelData.endDateTime, "hh:mm"); color: "#aaa9bb"; font.pixelSize: 11 }
            }
            HoverHandler { id: eventHover }
            ToolTip.visible: eventHover.hovered
            ToolTip.text: modelData.title + (modelData.description ? "\n" + modelData.description : "")
        }
    }
}
