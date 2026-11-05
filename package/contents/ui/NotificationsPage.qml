pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: page
    objectName: "notificationsPage"
    required property var backend
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
        delegate: RowLayout {
            id: notification
            required property var model
            width: ListView.view.width - 12
            ColumnLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: notification.model.applicationName || ""; textFormat: Text.PlainText; color: "#aaa0c9"; elide: Text.ElideRight; font.pixelSize: 11 }
                Label { Layout.fillWidth: true; text: notification.model.summary || ""; textFormat: Text.PlainText; color: "#f3f2fa"; wrapMode: Text.Wrap; font.bold: true }
                Label { Layout.fillWidth: true; text: notification.model.body || ""; textFormat: Text.StyledText; color: "#9899aa"; wrapMode: Text.Wrap; onLinkActivated: link => Qt.openUrlExternally(link) }
            }
            ActionButton { objectName: "deleteNotification_" + notification.model.notificationId; text: "×"; Accessible.description: strings.text("Delete notification"); onClicked: page.backend.closeId(notification.model.notificationId) }
        }
    }
}
