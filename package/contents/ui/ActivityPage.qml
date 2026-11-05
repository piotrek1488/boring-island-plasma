pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    objectName: "activityPage"
    required property var backend
    property string language: "en"
    property string pinnedMode: "auto"
    signal pinRequested(string mode)
    Translations { id: strings; language: page.language }
    contentWidth: availableWidth
    ColumnLayout {
        width: page.availableWidth; spacing: 10
        RowLayout {
            Label { text: strings.text("Panel view:"); color: "#f3f2fa" }
            ComboBox {
                Layout.fillWidth: true
                model: [strings.text("Automatic"), strings.text("Clock"), strings.text("Media"), strings.text("System"), strings.text("Packages"), strings.text("Local AI"), strings.text("Notifications")]
                currentIndex: Math.max(0, ["auto", "clock", "media", "system", "packages", "llm", "notifications"].indexOf(page.pinnedMode))
                onActivated: index => page.pinRequested(["auto", "clock", "media", "system", "packages", "llm", "notifications"][index])
            }
        }
        Label { visible: page.backend.error !== ""; text: strings.text("Activity data unavailable"); color: "#f4a4a4" }
        RowLayout {
            visible: page.backend.systemEnabled
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: strings.text("System"); color: "#aaa0c9"; font.bold: true }
                Label {
                    Layout.fillWidth: true; wrapMode: Text.Wrap; color: "#f3f2fa"
                    text: "CPU " + (page.backend.system.cpu === undefined || page.backend.system.cpu === null ? "—" : page.backend.system.cpu + "%") + " · RAM " + (page.backend.system.ram === undefined ? "—" : page.backend.system.ram + "%")
                }
                Repeater {
                    model: page.backend.system.gpus || []
                    delegate: Label { required property var modelData; text: modelData.name + " · " + modelData.util + "%"; textFormat: Text.PlainText; color: "#9899aa" }
                }
            }
            ActionButton { text: "↗"; Accessible.description: strings.text("Open System Monitor"); onClicked: page.backend.open("system") }
        }
        RowLayout {
            visible: page.backend.packagesEnabled
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: strings.text("Packages"); color: "#aaa0c9"; font.bold: true }
                Label {
                    Layout.fillWidth: true; wrapMode: Text.Wrap; color: "#f3f2fa"; textFormat: Text.PlainText
                    text: page.backend.packages.active ? page.backend.packages.tool + " · " + page.backend.packages.operation + " · " + (page.backend.packages.package || "") : strings.text("No package operations detected")
                }
                ProgressBar { Layout.fillWidth: true; visible: page.backend.packages.active; indeterminate: true }
                Label { Layout.fillWidth: true; wrapMode: Text.Wrap; text: strings.text("Activity detection only; installation result is not verified."); color: "#9899aa"; font.pixelSize: 11 }
            }
            ActionButton { text: "↗"; enabled: page.backend.packages.active; Accessible.description: strings.text("Focus installation terminal (requires kdotool)"); onClicked: page.backend.open("packages") }
        }
        RowLayout {
            visible: page.backend.llmEnabled
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: strings.text("Local AI"); color: "#aaa0c9"; font.bold: true }
                Label {
                    Layout.fillWidth: true; wrapMode: Text.Wrap; color: "#f3f2fa"; textFormat: Text.PlainText
                    text: page.backend.llm.active ? page.backend.llm.runner + " · " + page.backend.llm.model : strings.text("No local models detected")
                }
                Label { visible: page.backend.llm.active; text: strings.text("Context:") + " " + (page.backend.llm.context || "—"); color: "#9899aa" }
                Label {
                    visible: page.backend.llm.active
                    text: page.backend.llm.phase === "idle" ? strings.text("Idle") : page.backend.llm.phase === "processing" ? strings.text("Processing") : page.backend.llm.phase === "generating" ? strings.text("Generating") : strings.text("Generation state unavailable")
                    color: "#9899aa"
                }
                Label { visible: page.backend.llm.tokens_per_second !== undefined && page.backend.llm.tokens_per_second !== null; text: Number(page.backend.llm.tokens_per_second || 0).toFixed(1) + " tok/s"; color: "#a7e7b8" }
                Label { visible: page.backend.llm.cpu !== undefined && page.backend.llm.cpu !== null; text: "CPU · " + page.backend.llm.cpu + "%"; color: "#9899aa" }
                Label { visible: !!page.backend.llm.process_memory; text: "RSS · " + (Number(page.backend.llm.process_memory || 0) / 1073741824).toFixed(2) + " GiB"; color: "#9899aa" }
                Label { visible: !!page.backend.llm.memory; text: "RAM/VRAM · " + (Number(page.backend.llm.memory || 0) / 1073741824).toFixed(1) + " GiB"; color: "#9899aa" }
            }
            ActionButton { text: "↗"; enabled: page.backend.llm.active; Accessible.description: strings.text("Open local AI runner"); onClicked: page.backend.open("llm") }
        }
    }
}
