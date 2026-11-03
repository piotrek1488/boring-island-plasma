pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kdeconnect as KDEConnect
import "../code/Shelf.js" as Shelf
ColumnLayout {
    id: sharePage
    property string selectedUrl: ""
    property string statusText: ""
    property bool sending: false
    signal backRequested()
    spacing: 6
    onSelectedUrlChanged: statusText = ""
    KDEConnect.DevicesModel {
        id: devices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }
    RowLayout {
        ActionButton { text: "‹"; implicitWidth: 30; implicitHeight: 28; enabled: !sharePage.sending; Accessible.description: qsTr("Back to shelf"); onClicked: sharePage.backRequested() }
        Text { Layout.fillWidth: true; text: Shelf.name(sharePage.selectedUrl); textFormat: Text.PlainText; elide: Text.ElideMiddle; color: "#eeeaf8"; font.pixelSize: 12 }
        ActionButton { text: "⚙"; implicitWidth: 30; implicitHeight: 28; Accessible.description: qsTr("Pair devices in KDE Connect"); onClicked: KDEConnect.OpenConfig.openConfiguration() }
    }
    Text {
        visible: devices.count === 0
        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#aaa9bb"; font.pixelSize: 12
        text: qsTr("No paired device is reachable. Open KDE Connect on both devices, connect to the same network and pair them using the settings button.")
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
                onSubmitted: { sharePage.sending = false; sharePage.statusText = qsTr("Handed to KDE Connect. Check its notification for transfer completion."); }
                onFailed: message => { sharePage.sending = false; sharePage.statusText = qsTr("Could not start transfer: ") + message; }
            }
            Text { Layout.fillWidth: true; text: deviceRow.model.name; textFormat: Text.PlainText; color: "#eeeaf8"; elide: Text.ElideRight }
            ActionButton {
                text: transfer.available ? qsTr("Send") : qsTr("Unavailable")
                implicitWidth: 105; implicitHeight: 32
                enabled: transfer.available && !sharePage.sending && Shelf.allowed(sharePage.selectedUrl)
                onClicked: { sharePage.sending = true; sharePage.statusText = qsTr("Starting transfer…"); transfer.send(sharePage.selectedUrl); }
            }
        }
    }
    Text { Layout.fillWidth: true; text: sharePage.statusText; textFormat: Text.PlainText; wrapMode: Text.WordWrap; color: "#c4b5fd"; font.pixelSize: 11; visible: text.length > 0 }
}
