pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/Shelf.js" as Shelf
Item {
    id: view
    property var calendarBackend: null
    property string calendarMode: "kde"
    property string calendarSources: ""
    property int calendarAppletId: 0
    property string language: "en"
    Translations { id: strings; language: view.language }
    required property var backend
    property var notifications: null
    property var activities: null
    property string pinnedMode: "auto"
    property bool drawSurface: true
    signal pinRequested(string mode)
    property bool notch: false
    property bool showBattery: true
    property bool reduceMotion: false
    property var shelf: []
    property int page: 0
    property string selectedShareUrl: ""
    readonly property bool interactionHeld: page === 2
    signal interactionHeldChangedByUser(bool held)
    onInteractionHeldChanged: interactionHeldChangedByUser(interactionHeld)
    property date currentDate: new Date()
    readonly property string today: currentDate.toLocaleDateString(strings.locale, "ddd, d MMM yyyy")
    onVisibleChanged: { if (!visible) hoverChanged(false); }
    signal shelfEdited(var urls)
    signal hoverChanged(bool hovered)
    signal closeRequested()
    implicitWidth: 440; implicitHeight: 286
    function addFiles(urls) { shelfEdited(Shelf.merge(shelf, urls)); page = 1; }
    function timeLabel(us) { var s = Math.max(0, Math.floor(us / 1000000)); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60; }
    IslandSurface { anchors.fill: parent; notch: view.notch; visible: view.drawSurface }
    HoverHandler { onHoveredChanged: view.hoverChanged(hovered) }
    DropArea { anchors.fill: parent; onDropped: drop => { if (drop.hasUrls) { view.addFiles(drop.urls); drop.acceptProposedAction(); } } }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 26; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { objectName: "brandLabel"; text: "BORING / ISLAND"; color: "#aaa0c9"; font.pixelSize: 10; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            Text { objectName: "headerDate"; text: view.today; color: "#c1c2d0"; font.pixelSize: 13 }
        }
        Flow {
            objectName: "tabs"
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: 5
            ActionButton { text: strings.text("Media"); showTooltip: false; implicitHeight: 34; accent: view.page === 0; onClicked: view.page = 0 }
            ActionButton { text: strings.text("Shelf") + " · " + view.shelf.length; showTooltip: false; implicitHeight: 34; accent: view.page === 1; onClicked: view.page = 1 }
            ActionButton { objectName: "calendarTab"; text: strings.text("Calendar"); showTooltip: false; implicitHeight: 34; accent: view.page === 3; onClicked: view.page = 3 }
            ActionButton { objectName: "notificationsTab"; text: strings.text("Notifications") + (view.notifications ? " · " + view.notifications.count : ""); showTooltip: false; implicitHeight: 34; accent: view.page === 4; onClicked: view.page = 4 }
            ActionButton { text: strings.text("Activity"); showTooltip: false; implicitHeight: 34; accent: view.page === 5; onClicked: view.page = 5 }
        }
        StackLayout {
            currentIndex: view.page; Layout.fillWidth: true; Layout.fillHeight: true; clip: true
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
                        Text { Layout.fillWidth: true; text: view.backend.title || strings.text("Nothing playing"); textFormat: Text.PlainText; color: "#f3f2fa"; font.pixelSize: 19; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: view.backend.artist || strings.text("Start a player with MPRIS support"); textFormat: Text.PlainText; color: "#9899aa"; font.pixelSize: 12; elide: Text.ElideRight }
                        RowLayout {
                            ActionButton { objectName: "previousButton"; text: "|‹"; enabled: view.backend.canPrevious; Accessible.description: strings.text("Previous track"); onClicked: view.backend.previous() }
                            ActionButton { objectName: "playButton"; text: view.backend.playing ? "Ⅱ" : "▶"; accent: true; enabled: view.backend.canToggle; Accessible.description: view.backend.playing ? strings.text("Pause") : strings.text("Play"); onClicked: view.backend.toggle() }
                            ActionButton { text: "↗"; enabled: !!view.backend.canRaise; Accessible.description: strings.text("Open media player"); onClicked: view.backend.raisePlayer() }
                            ActionButton { objectName: "nextButton"; text: "›|"; enabled: view.backend.canNext; Accessible.description: strings.text("Next track"); onClicked: view.backend.next() }
                        }
                    }
                }
                RowLayout {
                    Text { text: view.timeLabel(view.backend.position); color: "#9395a7"; font.pixelSize: 10 }
                    Slider {
                        id: seek; objectName: "seekSlider"; Layout.fillWidth: true; from: 0; to: Math.max(1, view.backend.duration)
                        value: view.backend.position; enabled: view.backend.canSeek
                        Accessible.name: strings.text("Track position")
                        onMoved: view.backend.seek(value)
                    }
                    Text { text: view.timeLabel(view.backend.duration); color: "#9395a7"; font.pixelSize: 10 }
                }
                RowLayout {
                    Text { Layout.fillWidth: true; text: (view.backend.identity || "MPRIS · Plasma 6") + (view.activities && view.activities.audio ? " · " + view.activities.audio : ""); textFormat: Text.PlainText; color: "#77798d"; font.pixelSize: 10; elide: Text.ElideRight }
                    Text { text: strings.text("Volume"); color: "#9395a7"; font.pixelSize: 10 }
                    Slider { Layout.preferredWidth: 110; from: 0; to: 1; value: view.backend.volume; enabled: view.backend.available; Accessible.name: strings.text("Player volume"); onMoved: view.backend.setVolume(value) }
                }
            }
            Item {
                Text {
                    anchors.centerIn: parent; width: parent.width; visible: view.shelf.length === 0
                    text: strings.text("Drop files here") + "\n" + strings.text("A shelf of shortcuts · up to 24 files")
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
                        ActionButton { objectName: "shareFileButton"; text: "↗"; implicitWidth: 30; implicitHeight: 30; Accessible.description: strings.text("Send with KDE Connect"); onClicked: { view.selectedShareUrl = shelfRow.modelData; view.page = 2; } }
                        ActionButton { text: "×"; implicitWidth: 30; implicitHeight: 30; Accessible.description: strings.text("Remove shortcut"); onClicked: { var items = view.shelf.slice(); items.splice(shelfRow.index, 1); view.shelfEdited(items); } }
                    }
                }
            }
            Item {
                Loader {
                    id: shareLoader
                    anchors.fill: parent
                    active: view.page === 2
                    source: "SharePage.qml"
                    onLoaded: {
                        item.selectedUrl = Qt.binding(() => view.selectedShareUrl);
                        item.language = Qt.binding(() => view.language);
                    }
                }
                Connections { target: shareLoader.item; function onBackRequested() { view.page = 1; } }
                Text { anchors.fill: parent; visible: shareLoader.status === Loader.Error; text: strings.text("Install KDE Connect and its QML module to send files."); color: "#aaa9bb"; wrapMode: Text.WordWrap }
            }
            Loader {
                id: calendarLoader
                active: view.page === 3
                function loadCalendar() {
                    if (active) setSource("CalendarPage.qml", {backend: view.calendarBackend, language: view.language,
                        calendarMode: view.calendarMode, calendarSources: view.calendarSources, calendarAppletId: view.calendarAppletId});
                }
                onActiveChanged: loadCalendar()
                Component.onCompleted: loadCalendar()
                onLoaded: {
                    item.backend = Qt.binding(() => view.calendarBackend);
                    item.language = Qt.binding(() => view.language);
                    item.calendarMode = Qt.binding(() => view.calendarMode);
                    item.calendarSources = Qt.binding(() => view.calendarSources);
                    item.calendarAppletId = Qt.binding(() => view.calendarAppletId);
                }
            }
            Loader {
                id: notificationsLoader
                active: view.page === 4 && view.notifications !== null
                onActiveChanged: if (active) setSource("NotificationsPage.qml", {backend: view.notifications, language: view.language})
                Component.onCompleted: if (active) setSource("NotificationsPage.qml", {backend: view.notifications, language: view.language})
                onLoaded: item.language = Qt.binding(() => view.language)
            }
            Connections { target:notificationsLoader.item; function onApplicationOpened() { view.closeRequested(); } }
            Loader {
                active: view.page === 5 && view.activities !== null
                id: activityLoader
                onActiveChanged: if (active) setSource("ActivityPage.qml", {backend: view.activities, language: view.language, pinnedMode: view.pinnedMode})
                Component.onCompleted: if (active) setSource("ActivityPage.qml", {backend: view.activities, language: view.language, pinnedMode: view.pinnedMode})
                onLoaded: {
                    item.language = Qt.binding(() => view.language);
                    item.pinnedMode = Qt.binding(() => view.pinnedMode);
                }
                Connections { target: activityLoader.item; function onPinRequested(mode) { view.pinRequested(mode); } }
            }
        }
    }
    Keys.onEscapePressed: closeRequested()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: view.currentDate = new Date() }
}
