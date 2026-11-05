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
    property bool presentedFullView: false
    property bool fixedViewport: false
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
    readonly property real expandedHeaderHeight: Math.max(compactHeight, 56 * uiScale)
    readonly property real bodyHeight: Math.max(0, Math.min(maximumHeight - expandedHeaderHeight, (presentedFullView ? expandedHeight : 126) * uiScale))
    readonly property real surfaceWidth: compactWidth + (targetWidth - compactWidth) * progress
    readonly property real headerHeight: compactHeight + (expandedHeaderHeight - compactHeight) * progress
    readonly property real surfaceHeight: headerHeight + bodyHeight * progress
    width: fixedViewport ? targetWidth : surfaceWidth
    height: fixedViewport ? expandedHeaderHeight + bodyHeight : surfaceHeight
    Behavior on progress { NumberAnimation { duration: shell.reduceMotion ? 0 : 460; easing.type: Easing.OutCubic } }
    Item {
        id: morph
        objectName: "morphSurface"
        width: shell.surfaceWidth; height: shell.surfaceHeight
        x: (shell.width - width) / 2
        y: shell.bottomEdge ? shell.height - height : 0
        clip: true
        IslandSurface { anchors.fill: parent; notch: shell.notch }
        CompactView {
            width: morph.width; height: shell.headerHeight
            expandedHeader: shell.progress > 0.5; minimumTextScale: 0.5 + 0.5 * shell.progress; compactScale: 1
            edgeInset: 16 + 16 * shell.progress
            batteryFontSize: 11 + 3 * shell.progress
            y: shell.bottomEdge ? morph.height - height : 0
            backend: shell.backend; language: shell.language; notch: shell.notch
            showBattery: shell.showBattery; displayText: shell.displayText
            drawSurface: false; accentColor: shell.accentColor
            onActivated: shell.activated()
            onFilesDropped: urls => shell.filesDropped(urls)
        }
        Item {
            y: shell.bottomEdge ? 0 : shell.headerHeight
            x: (morph.width - width) / 2
            width: shell.targetWidth
            height: shell.bodyHeight
            opacity: Math.max(0, (shell.progress - 0.25) / 0.75)
            Item {
                width: parent.width / shell.uiScale; height: parent.height / shell.uiScale
                scale: shell.uiScale; transformOrigin: Item.TopLeft
                IslandView {
                    id: content
                    anchors.fill: parent
                    visible: shell.presentedFullView
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
                    visible: !shell.presentedFullView && shell.notifications.preview !== null
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
    }
    onInitialPageChanged: content.page = initialPage
    onFullViewChanged: if (fullView) { presentedFullView = true; content.page = initialPage; }
    onProgressChanged: if (progress === 0 && !opened) presentedFullView = false
    Component.onCompleted: if (fullView) presentedFullView = true
    Keys.onEscapePressed: closeRequested()
}
