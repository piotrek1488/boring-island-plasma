pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: page
    objectName: "notificationsPage"
    required property var backend
    signal applicationOpened()
    property string language: "en"
    Translations { id: strings; language: page.language }
    RowLayout {
        Layout.fillWidth: true
        Label { Layout.fillWidth: true; text: strings.text("Notifications") + " · " + page.backend.count; color: "#f3f2fa" }
        ActionButton { text: strings.text("Clear all"); enabled: page.backend.count > 0; onClicked: page.backend.clearAll() }
    }
    Label {
        visible: page.backend.count === 0
        text: page.backend.available ? strings.text("No notifications") : strings.text("Open this widget in Plasma to share notification history.")
        wrapMode: Text.WordWrap; Layout.fillWidth: true; color: "#9899aa"
    }
    ListView {
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true; spacing: 8
        model: page.backend.history
        ScrollBar.vertical: ScrollBar {}
        delegate: NotificationCard {
            id: notification
            required property var model
            width: ListView.view.width - 12
            backend: page.backend; language: page.language
            note: ({id:String(model.notificationId), application:model.applicationName || "", summary:model.summary || "", body:model.body || ""})
            onApplicationOpened: page.applicationOpened()
        }
    }
}
