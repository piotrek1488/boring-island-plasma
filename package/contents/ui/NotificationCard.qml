pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card
    required property var backend
    property var note: null
    property string language: "en"
    property int maximumSummaryLines: 2
    property int maximumBodyLines: 2147483647
    readonly property bool canOpen: {
        const revision = backend.actionRevision || 0;
        return note !== null && typeof backend.canOpenId === "function" && backend.canOpenId(note.id);
    }
    signal applicationOpened()
    Connections {
        target: card.backend
        ignoreUnknownSignals: true
        function onApplicationLaunchFinished(id, success) { if (success && card.visible && card.note && String(card.note.id)===String(id)) card.applicationOpened(); }
    }
    function openApplication() {
        if (canOpen && backend.openId(note.id, card.Window.window)) applicationOpened();
    }
    implicitHeight: Math.max(56, content.implicitHeight + 28)
    radius: 10
    color: hover.hovered ? "#262833" : "#191a22"
    Accessible.role: Accessible.ListItem
    Accessible.name: note ? note.application + " · " + note.summary : ""
    HoverHandler { id: hover }
    MouseArea {
        objectName: "notificationClick_" + (card.note ? card.note.id : "")
        anchors.fill: parent
        cursorShape: card.canOpen ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: card.openApplication()
    }
    RowLayout {
        id: content
        anchors.fill: parent; anchors.margins: 14; spacing: 8
        ColumnLayout {
            Layout.fillWidth: true; spacing: 3
            Label { Layout.fillWidth: true; text: card.note ? card.note.application : ""; textFormat: Text.PlainText; color: "#aaa0c9"; elide: Text.ElideRight; font.pixelSize: 11 }
            Label { Layout.fillWidth: true; text: card.note ? card.note.summary : ""; textFormat: Text.PlainText; color: "#f3f2fa"; wrapMode: Text.Wrap; font.bold: true; maximumLineCount:card.maximumSummaryLines; elide:Text.ElideRight }
            Label { Layout.fillWidth: true; text: card.note ? card.note.body : ""; textFormat: Text.StyledText; color: "#9899aa"; wrapMode: Text.Wrap; maximumLineCount:card.maximumBodyLines; elide:Text.ElideRight; onLinkActivated: link=>Qt.openUrlExternally(link) }
        }
        ActionButton {
            objectName: "openNotification_" + (card.note ? card.note.id : "")
            text: "↗"; implicitWidth: 30; implicitHeight: 30; leftPadding:3; rightPadding:3
            enabled: card.canOpen
            Accessible.name: strings.text("Open source application")
            Accessible.description: card.canOpen ? strings.text("Open source application") : strings.text("This notification has no application action.")
            onClicked: card.openApplication()
        }
        ActionButton {
            objectName: "deleteNotification_" + (card.note ? card.note.id : "")
            text: "×"; implicitWidth:30; implicitHeight:30; leftPadding:3; rightPadding:3
            Accessible.description: strings.text("Delete notification")
            onClicked: if (card.note) card.backend.closeId(card.note.id)
        }
    }
    Translations { id: strings; language: card.language }
}
