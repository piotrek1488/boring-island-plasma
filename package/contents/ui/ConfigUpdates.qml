import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: updates
    property string cfg_language: "en"
    property var backend: updater
    Translations { id: strings; language: updates.cfg_language }
    UpdateBackend { id: updater }
    clip: true
    contentWidth: availableWidth
    implicitWidth: 640; implicitHeight: 400
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ColumnLayout {
        width: updates.availableWidth
        spacing: 16
        Label { objectName: "updatesTitle"; text: strings.text("Updates"); font.pixelSize: 24; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Label { text: strings.text("Installed version:") + " " + updates.backend.installedVersion; Layout.alignment: Qt.AlignHCenter }
        Label {
            objectName: "updateStatus"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            text: updates.backend.state === "available" ? strings.text("Update available:") + " " + updates.backend.latestVersion
                : updates.backend.state === "checking" ? strings.text("Checking for updates…")
                : updates.backend.state === "installing" ? strings.text("Installing update…")
                : updates.backend.state === "restarting" ? strings.text("Restarting Plasma…")
                : updates.backend.state === "installed" ? strings.text("Update installed. Restart Plasma or log out and back in to load it.")
                : updates.backend.state === "current" ? strings.text("You are using the latest version.")
                : updates.backend.errorMessage ? strings.text(updates.backend.errorMessage) : ""
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Button {
                objectName: "checkUpdatesButton"
                text: strings.text("Check for updates")
                enabled: !updates.backend.busy && updates.backend.state !== "installed"
                onClicked: updates.backend.check()
            }
            Button {
                objectName: "githubLoginButton"
                text: strings.text("Sign in to GitHub")
                visible: updates.backend.state === "authRequired"
                enabled: !updates.backend.busy
                onClicked: updates.backend.login()
            }
            Button {
                objectName: "installUpdateButton"
                text: strings.text("Install update")
                visible: updates.backend.state === "available" || updates.backend.state === "installing"
                enabled: updates.backend.state === "available" && !updates.backend.busy
                onClicked: updates.backend.install()
            }
            Button {
                objectName: "restartPlasmaButton"
                text: strings.text("Restart Plasma")
                visible: updates.backend.state === "installed" || updates.backend.state === "restarting"
                enabled: !updates.backend.busy
                onClicked: updates.backend.restart()
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
            text: strings.text("Updates come from this project's GitHub releases. The package checksum is verified before installation. Widget settings are kept.")
        }
    }
}
