pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/Shelf.js" as Shelf
Item {
    id: view
    required property var backend
    property bool notch: false
    property bool showBattery: true
    property bool reduceMotion: false
    property var shelf: []
    property int page: 0
    property string selectedShareUrl: ""
    readonly property bool interactionHeld: page === 2
    signal interactionHeldChangedByUser(bool held)
    onInteractionHeldChanged: interactionHeldChangedByUser(interactionHeld)
    property string today: Qt.formatDate(new Date(), "ddd, d MMM")
    onVisibleChanged: { if (!visible) hoverChanged(false); }
    signal shelfEdited(var urls)
    signal hoverChanged(bool hovered)
    signal closeRequested()
    implicitWidth: 440; implicitHeight: 286
    function addFiles(urls) { shelfEdited(Shelf.merge(shelf, urls)); page = 1; }
    function timeLabel(us) { var s = Math.max(0, Math.floor(us / 1000000)); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60; }
    IslandSurface { anchors.fill: parent; notch: view.notch }
    HoverHandler { onHoveredChanged: view.hoverChanged(hovered) }
    DropArea { anchors.fill: parent; onDropped: drop => { if (drop.hasUrls) { view.addFiles(drop.urls); drop.acceptProposedAction(); } } }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 22; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "BORING / ISLAND"; color: "#aaa0c9"; font.pixelSize: 10; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            Text { text: view.today; color: "#9395a7"; font.pixelSize: 11 }
            ActionButton { text: "×"; implicitWidth: 26; implicitHeight: 26; Accessible.description: qsTr("Close"); onClicked: view.closeRequested() }
        }
        RowLayout {
            spacing: 8
            ActionButton { text: qsTr("Media"); implicitWidth: 70; implicitHeight: 30; accent: view.page === 0; onClicked: view.page = 0 }
            ActionButton { text: qsTr("Shelf") + " · " + view.shelf.length; implicitWidth: 85; implicitHeight: 30; accent: view.page === 1; onClicked: view.page = 1 }
            ActionButton { objectName: "calendarTab"; text: qsTr("Calendar"); implicitWidth: 92; implicitHeight: 30; accent: view.page === 3; onClicked: view.page = 3 }
            Item { Layout.fillWidth: true }
            Text { visible: view.showBattery && view.backend.hasBattery; text: (view.backend.charging ? "+ " : "") + view.backend.percent + "%"; color: "#a7e7b8"; font.pixelSize: 12 }
        }
        StackLayout {
            currentIndex: view.page; Layout.fillWidth: true; Layout.fillHeight: true
            ColumnLayout {
                spacing: 8
                RowLayout {
                    spacing: 16
                    Rectangle {
                        implicitWidth: 88; implicitHeight: 88; radius: 18; color: "#242130"; clip: true
                        Text { anchors.centerIn: parent; text: "♫"; color: "#c4b5fd"; font.pixelSize: 40 }
                        Image { anchors.fill: parent; source: view.backend.artwork; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 5
                        Text { Layout.fillWidth: true; text: view.backend.title || qsTr("Nothing playing"); textFormat: Text.PlainText; color: "#f3f2fa"; font.pixelSize: 19; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: view.backend.artist || qsTr("Start a player with MPRIS support"); textFormat: Text.PlainText; color: "#9899aa"; font.pixelSize: 12; elide: Text.ElideRight }
                        RowLayout {
                            ActionButton { objectName: "previousButton"; text: "|‹"; enabled: view.backend.canPrevious; Accessible.description: qsTr("Previous track"); onClicked: view.backend.previous() }
                            ActionButton { objectName: "playButton"; text: view.backend.playing ? "Ⅱ" : "▶"; accent: true; enabled: view.backend.canToggle; Accessible.description: view.backend.playing ? qsTr("Pause") : qsTr("Play"); onClicked: view.backend.toggle() }
                            ActionButton { objectName: "nextButton"; text: "›|"; enabled: view.backend.canNext; Accessible.description: qsTr("Next track"); onClicked: view.backend.next() }
                        }
                    }
                }
                RowLayout {
                    Text { text: view.timeLabel(view.backend.position); color: "#9395a7"; font.pixelSize: 10 }
                    Slider {
                        id: seek; objectName: "seekSlider"; Layout.fillWidth: true; from: 0; to: Math.max(1, view.backend.duration)
                        value: view.backend.position; enabled: view.backend.canSeek
                        Accessible.name: qsTr("Track position")
                        onMoved: view.backend.seek(value)
                    }
                    Text { text: view.timeLabel(view.backend.duration); color: "#9395a7"; font.pixelSize: 10 }
                }
                RowLayout {
                    Text { Layout.fillWidth: true; text: view.backend.identity || "MPRIS · Plasma 6"; textFormat: Text.PlainText; color: "#77798d"; font.pixelSize: 10; elide: Text.ElideRight }
                    Text { text: qsTr("Volume"); color: "#9395a7"; font.pixelSize: 10 }
                    Slider { Layout.preferredWidth: 110; from: 0; to: 1; value: view.backend.volume; enabled: view.backend.available; Accessible.name: qsTr("Player volume"); onMoved: view.backend.setVolume(value) }
                }
            }
            Item {
                Text {
                    anchors.centerIn: parent; width: parent.width; visible: view.shelf.length === 0
                    text: qsTr("Drop files here") + "\n" + qsTr("A shelf of shortcuts · up to 24 files")
                    color: "#9899aa"; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 15; lineHeight: 1.6
                }
                ListView {
                    anchors.fill: parent; clip: true; spacing: 5; model: view.shelf
                    ScrollBar.vertical: ScrollBar {}
                    delegate: RowLayout {
                        id: shelfRow
                        required property string modelData
                        required property int index
                        width: ListView.view.width - 12; spacing: 8
                        Button {
                            id: fileButton
                            Drag.active: fileDrag.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction
                            Drag.proposedAction: Qt.CopyAction
                            Drag.mimeData: ({"text/uri-list": shelfRow.modelData})
                            DragHandler { id: fileDrag; target: null }
                            Layout.fillWidth: true; text: Shelf.name(shelfRow.modelData)
                            onClicked: Qt.openUrlExternally(shelfRow.modelData)
                            ToolTip.visible: hovered; ToolTip.text: shelfRow.modelData
                            contentItem: Text { text: fileButton.text; color: "#eeeaf8"; elide: Text.ElideMiddle; textFormat: Text.PlainText; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: "#20212a"; radius: 8 }
                        }
                        ActionButton { objectName: "shareFileButton"; text: "↗"; implicitWidth: 30; implicitHeight: 30; Accessible.description: qsTr("Send with KDE Connect"); onClicked: { view.selectedShareUrl = shelfRow.modelData; view.page = 2; } }
                        ActionButton { text: "×"; implicitWidth: 30; implicitHeight: 30; Accessible.description: qsTr("Remove shortcut"); onClicked: { var items = view.shelf.slice(); items.splice(shelfRow.index, 1); view.shelfEdited(items); } }
                    }
                }
            }
            Item {
                Loader {
                    id: shareLoader
                    anchors.fill: parent
                    active: view.page === 2
                    source: "SharePage.qml"
                    onLoaded: item.selectedUrl = Qt.binding(() => view.selectedShareUrl)
                }
                Connections { target: shareLoader.item; function onBackRequested() { view.page = 1; } }
                Text { anchors.fill: parent; visible: shareLoader.status === Loader.Error; text: qsTr("Install KDE Connect and its QML module to send files."); color: "#aaa9bb"; wrapMode: Text.WordWrap }
            }
            Loader {
                active: view.page === 3
                source: "CalendarPage.qml"
            }
        }
    }
    Keys.onEscapePressed: closeRequested()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: view.today = Qt.formatDate(new Date(), "ddd, d MMM") }
}
