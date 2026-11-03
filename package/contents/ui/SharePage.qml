pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kdeconnect as KDEConnect
import "../code/Shelf.js" as Shelf
ColumnLayout {
    id: sharePage
    property string language: "en"
    Translations { id: strings; language: sharePage.language }
    property string selectedUrl: ""
    property string statusKey: ""
    property string errorDetail: ""
    readonly property string statusText: strings.text(statusKey) + errorDetail
    property bool sending: false
    signal backRequested()
    spacing: 6
    onSelectedUrlChanged: { statusKey = ""; errorDetail = ""; }
    KDEConnect.DevicesModel {
        id: devices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }
    RowLayout {
        ActionButton { text: "‹"; implicitWidth: 30; implicitHeight: 28; enabled: !sharePage.sending; Accessible.description: strings.text("Back to shelf"); onClicked: sharePage.backRequested() }
        Text { Layout.fillWidth: true; text: Shelf.name(sharePage.selectedUrl); textFormat: Text.PlainText; elide: Text.ElideMiddle; color: "#eeeaf8"; font.pixelSize: 12 }
        ActionButton { text: "⚙"; implicitWidth: 30; implicitHeight: 28; Accessible.description: strings.text("Pair devices in KDE Connect"); onClicked: KDEConnect.OpenConfig.openConfiguration() }
    }
    Text {
        visible: devices.count === 0
        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#aaa9bb"; font.pixelSize: 12
        text: strings.text("No paired device is reachable. Open KDE Connect on both devices, connect to the same network and pair them using the settings button.")
    }
    ListView {
        id: deviceList
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
        model: devices
        ScrollBar.vertical: ScrollBar {}
        delegate: RowLayout {
            id: deviceRow
            required property var model
            width: ListView.view.width - 12
            ShareTarget {
                id: transfer
                deviceId: deviceRow.model.deviceId
                language: sharePage.language
                onSubmitted: { sharePage.sending = false; sharePage.statusKey = "Handed to KDE Connect. Check its notification for transfer completion."; sharePage.errorDetail = ""; }
                onFailed: message => { sharePage.sending = false; sharePage.statusKey = "Could not start transfer: "; sharePage.errorDetail = message; }
            }
            Text { Layout.fillWidth: true; text: deviceRow.model.name; textFormat: Text.PlainText; color: "#eeeaf8"; elide: Text.ElideRight }
            ActionButton {
                text: transfer.available ? strings.text("Send") : strings.text("Unavailable")
                implicitWidth: 105; implicitHeight: 32
                enabled: transfer.available && !sharePage.sending && Shelf.allowed(sharePage.selectedUrl)
                onClicked: { sharePage.sending = true; sharePage.statusKey = "Starting transfer…"; sharePage.errorDetail = ""; transfer.send(sharePage.selectedUrl); }
            }
        }
    }
    Text { Layout.fillWidth: true; text: sharePage.statusText; textFormat: Text.PlainText; wrapMode: Text.WordWrap; color: "#c4b5fd"; font.pixelSize: 11; visible: text.length > 0 }
}
