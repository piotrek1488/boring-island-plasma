import QtQuick
import org.kde.kdeconnect as KDEConnect
import "../code/Shelf.js" as Shelf
Item {
    id: target
    required property string deviceId
    property bool busy: false
    readonly property var device: KDEConnect.DeviceDbusInterfaceFactory.create(deviceId)
    readonly property bool available: checker.available
    readonly property var shareInterface: available ? KDEConnect.ShareDbusInterfaceFactory.create(deviceId) : null
    signal submitted()
    signal failed(string message)
    KDEConnect.PluginChecker { id: checker; device: target.device; pluginName: "share" }
    KDEConnect.DBusAsyncResponse {
        id: response
        autoDelete: false
        onSuccess: { target.busy = false; target.submitted(); }
        onError: message => { target.busy = false; target.failed(message); }
    }
    function send(url) {
        if (busy) return;
        if (!available || !shareInterface || !Shelf.allowed(url)) {
            failed(qsTr("Device unavailable or unsupported file address."));
            return;
        }
        busy = true;
        response.setPendingCall(shareInterface.shareUrl(url));
    }
}
