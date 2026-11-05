pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/CalendarMath.js" as CalendarMath

ColumnLayout {
    id: month
    objectName: "calendarMonth"
    property string language: "en"
    property date selectedDate: new Date()
    property date today: new Date()
    property var eventDays: ({})
    property int firstDayOfWeek: strings.locale.firstDayOfWeek
    readonly property var days: CalendarMath.monthDays(selectedDate, firstDayOfWeek)
    signal dateSelected(date value)
    spacing: 3
    Translations { id: strings; language: month.language }
    RowLayout {
        Layout.fillWidth: true; spacing: 2
        ActionButton {
            objectName: "previousMonth"; text: "‹"; implicitWidth: 26; implicitHeight: 26
            leftPadding: 2; rightPadding: 2
            Accessible.description: strings.text("Previous month")
            onClicked: month.dateSelected(CalendarMath.moveMonth(month.selectedDate, -1))
        }
        Text {
            objectName: "monthTitle"; Layout.fillWidth: true
            text: month.selectedDate.toLocaleDateString(strings.locale, "MMMM yyyy")
            color: "#eeeaf8"; font.pixelSize: 12; font.bold: true
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }
        ActionButton {
            objectName: "nextMonth"; text: "›"; implicitWidth: 26; implicitHeight: 26
            leftPadding: 2; rightPadding: 2
            Accessible.description: strings.text("Next month")
            onClicked: month.dateSelected(CalendarMath.moveMonth(month.selectedDate, 1))
        }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 2
        Repeater {
            model: 7
            Text {
                required property int index
                Layout.fillWidth: true; Layout.preferredWidth: 1
                text: new Date(2024, 0, month.firstDayOfWeek + index).toLocaleDateString(strings.locale, "ddd").replace(/\.$/, "")
                horizontalAlignment: Text.AlignHCenter; color: "#9395a7"; font.pixelSize: 10
            }
        }
    }
    GridLayout {
        objectName: "monthGrid"
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 0
        columns: 7; rowSpacing: 2; columnSpacing: 2
        Repeater {
            model: month.days
            Button {
                id: day
                required property date modelData
                readonly property string dateKey: CalendarMath.key(modelData)
                readonly property bool selected: dateKey === CalendarMath.key(month.selectedDate)
                readonly property bool currentDay: dateKey === CalendarMath.key(month.today)
                readonly property bool inMonth: modelData.getMonth() === month.selectedDate.getMonth()
                objectName: "calendarDay_" + dateKey
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.preferredWidth: 1; Layout.preferredHeight: 24
                Layout.minimumWidth: 0; Layout.minimumHeight: 16
                padding: 0; hoverEnabled: true
                Accessible.name: modelData.toLocaleDateString(strings.locale, "dddd, d MMMM yyyy")
                Accessible.description: selected ? strings.text("Selected day") : currentDay ? strings.text("Today") : ""
                contentItem: Text {
                    text: day.modelData.getDate()
                    font.pixelSize: 11; font.bold: day.selected || day.currentDay
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    color: day.selected ? "#090a0e" : day.currentDay ? "#ff9494" : day.inMonth ? "#eeeaf8" : "#686979"
                }
                background: Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(day.width, day.height); height: width; radius: width / 2
                    color: day.selected ? "#c4b5fd" : day.hovered ? "#30313d" : "transparent"
                    border.width: day.activeFocus || day.currentDay ? 1 : 0
                    border.color: day.activeFocus ? "#eeeaf8" : "#ff9494"
                }
                Rectangle {
                    objectName: "eventDot_" + day.dateKey
                    visible: Boolean(month.eventDays[day.dateKey])
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    width: 3; height: 3; radius: 1.5; color: day.selected ? "#090a0e" : "#f6c177"
                }
                onClicked: month.dateSelected(modelData)
                ToolTip.visible: hovered
                ToolTip.delay: 600
                ToolTip.text: Accessible.name
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: month.today = new Date() }
}
