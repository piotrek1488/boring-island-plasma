import QtQuick
import QtTest
import org.kde.kdeconnect as KDEConnect
import "../../package/contents/ui" as UI
Item {
    width: 440; height: 286
    Rectangle { anchors.fill: parent; color: "#090a0e" }
    KDEConnect.DevicesModel { id: devices; displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable }
    UI.ShareTarget { id: target; deviceId: "test_phone" }
    UI.SharePage { id: page; width: 396; height: 170; selectedUrl: "file:///tmp/report%20space.pdf" }
    SignalSpy { id: success; target: target; signalName: "submitted" }
    SignalSpy { id: failure; target: target; signalName: "failed" }
    TestCase {
        name: "KdeConnectProtocol"; when: windowShown
        function test_transfer() {
            tryCompare(devices, "count", 1, 5000);
            tryCompare(target, "available", true);
            target.send("file:///tmp/report%20space.pdf");
            tryCompare(success, "count", 1); compare(target.busy, false);
            target.send("file:///tmp/failure.txt");
            tryCompare(failure, "count", 1); compare(target.busy, false);
            target.send("https://example.com");
            compare(failure.count, 2); compare(success.count, 1);
            page.statusKey = "Starting transfer…";
            compare(page.statusText, "Starting transfer…");
            page.language = "pl";
            compare(page.statusText, "Rozpoczynanie transferu…");
            page.language = "en"; page.statusKey = "";
            grabImage(page).save(Qt.resolvedUrl("../../docs/kde-connect.png").toString().replace("file://", ""));
        }
    }
}
