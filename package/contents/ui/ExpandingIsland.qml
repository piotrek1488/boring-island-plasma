pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: shell
    required property var backend
    required property var notifications
    required property var activities
    property string language: "en"
    property string displayText: ""
    property string pinnedMode: "auto"
    property color accentColor: "#b9a3ff"
    property bool opened: false
    property bool fullView: false
    property bool notch: false
    property bool bottomEdge: false
    property bool showBattery: true
    property bool reduceMotion: false
    property real uiScale: 1
    property real compactWidth: 240
    property real compactHeight: 42
    property real expandedWidth: 520
    property real expandedHeight: 390
    property var shelf: []
    property int initialPage: 0
    property real progress: opened ? 1 : 0
    signal closeRequested()
    signal activated()
    signal filesDropped(var urls)
    signal hoverChanged(bool hovered)
    signal shelfEdited(var urls)
    signal interactionHeldChangedByUser(bool held)
    signal pinRequested(string mode)
    property real maximumWidth: 4096
    property real maximumHeight: 4096
    readonly property real targetWidth: Math.min(maximumWidth, Math.max(compactWidth, expandedWidth * uiScale))
    property real bodyHeight: Math.max(0, Math.min(maximumHeight - compactHeight, (fullView ? expandedHeight : 126) * uiScale))
    Behavior on bodyHeight { NumberAnimation { duration: shell.reduceMotion ? 0 : 220; easing.type: Easing.InOutCubic } }
    width: compactWidth + (targetWidth - compactWidth) * progress
    height: compactHeight + bodyHeight * progress
    clip: true
    Behavior on progress { NumberAnimation { duration: shell.reduceMotion ? 0 : 280; easing.type: Easing.InOutCubic } }
    IslandSurface { anchors.fill: parent; notch: shell.notch }
    CompactView {
        width: shell.width; height: shell.compactHeight
        y: shell.bottomEdge ? shell.height - height : 0
        backend: shell.backend; language: shell.language; notch: shell.notch
        showBattery: shell.showBattery; displayText: shell.displayText
        drawSurface: false; accentColor: shell.accentColor
        onActivated: shell.activated()
        onFilesDropped: urls => shell.filesDropped(urls)
    }
    Item {
        y: shell.bottomEdge ? 0 : shell.compactHeight
        width: shell.targetWidth
        height: shell.bodyHeight
        opacity: shell.progress
        Item {
            width: parent.width / shell.uiScale; height: parent.height / shell.uiScale
            scale: shell.uiScale; transformOrigin: Item.TopLeft
            IslandView {
                id: content
                anchors.fill: parent
                visible: shell.fullView
                language: shell.language; backend: shell.backend; notifications: shell.notifications; activities: shell.activities
                drawSurface: false; notch: shell.notch; reduceMotion: shell.reduceMotion; showBattery: shell.showBattery
                shelf: shell.shelf; pinnedMode: shell.pinnedMode
                onShelfEdited: urls => shell.shelfEdited(urls)
                onCloseRequested: shell.closeRequested()
                onInteractionHeldChangedByUser: held => shell.interactionHeldChangedByUser(held)
                onPinRequested: mode => shell.pinRequested(mode)
            }
            RowLayout {
                anchors.fill: parent; anchors.margins: 18
                visible: !shell.fullView && shell.notifications.preview !== null
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: shell.notifications.preview ? shell.notifications.preview.application : ""; textFormat: Text.PlainText; color: "#aaa0c9"; elide: Text.ElideRight }
                    Label { Layout.fillWidth: true; text: shell.notifications.preview ? shell.notifications.preview.summary : ""; textFormat: Text.PlainText; color: "#f3f2fa"; elide: Text.ElideRight; font.bold: true }
                    Label { Layout.fillWidth: true; text: shell.notifications.preview ? shell.notifications.preview.body : ""; textFormat: Text.StyledText; color: "#9899aa"; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                }
                ActionButton { text: "×"; Accessible.description: strings.text("Delete notification"); onClicked: if (shell.notifications.preview) shell.notifications.closeId(shell.notifications.preview.id) }
            }
        }
    }
    Translations { id: strings; language: shell.language }
    HoverHandler { onHoveredChanged: shell.hoverChanged(hovered) }
    onInitialPageChanged: content.page = initialPage
    onFullViewChanged: if (fullView) content.page = initialPage
    Keys.onEscapePressed: closeRequested()
}
