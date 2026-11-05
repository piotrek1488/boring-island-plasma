import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: about
    property string cfg_language: "en"
    property var backend: updater
    Translations { id: strings; language: about.cfg_language }
    UpdateBackend { id: updater }
    clip: true
    contentWidth: availableWidth
    implicitWidth: 640; implicitHeight: 400
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ColumnLayout {
        width: about.availableWidth
        spacing: 16
        Label { text: "Boring Island"; font.pixelSize: 24; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Label { text: strings.text("Installed version:") + " " + about.backend.installedVersion; Layout.alignment: Qt.AlignHCenter }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            text: strings.text("A notch and Dynamic Island for KDE Plasma.")
        }
        Label {
            objectName: "updateStatus"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            text: about.backend.state === "available" ? strings.text("Update available:") + " " + about.backend.latestVersion
                : about.backend.state === "checking" ? strings.text("Checking for updates…")
                : about.backend.state === "installing" ? strings.text("Installing update…")
                : about.backend.state === "restarting" ? strings.text("Restarting Plasma…")
                : about.backend.state === "installed" ? strings.text("Update installed. Restart Plasma or log out and back in to load it.")
                : about.backend.state === "current" ? strings.text("You are using the latest version.")
                : about.backend.errorMessage ? strings.text(about.backend.errorMessage) : ""
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Button {
                objectName: "checkUpdatesButton"
                text: strings.text("Check for updates")
                enabled: !about.backend.busy && about.backend.state !== "installed"
                onClicked: about.backend.check()
            }
            Button {
                objectName: "installUpdateButton"
                text: strings.text("Install update")
                visible: about.backend.state === "available" || about.backend.state === "installing"
                enabled: about.backend.state === "available" && !about.backend.busy
                onClicked: about.backend.install()
            }
            Button {
                objectName: "restartPlasmaButton"
                text: strings.text("Restart Plasma")
                visible: about.backend.state === "installed" || about.backend.state === "restarting"
                enabled: !about.backend.busy
                onClicked: about.backend.restart()
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
            text: strings.text("Updates come from this project's GitHub releases. The package checksum is verified before installation. Widget settings are kept.")
        }
        Button {
            Layout.alignment: Qt.AlignHCenter
            text: strings.text("Project on GitHub")
            onClicked: Qt.openUrlExternally("https://github.com/piotrek1488/boring-island-plasma")
        }
    }
}
