pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../code/Shelf.js" as Shelf
import "../code/Activity.js" as Activity

PlasmoidItem {
    id: root
    readonly property string language: Plasmoid.configuration.language || "en"
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool notch: Plasmoid.configuration.shape === 0
    readonly property bool reduceMotion: Plasmoid.configuration.reduceMotion
    readonly property real compactScale: Math.max(0.5, Math.min(2, Plasmoid.configuration.compactScale / 100))
    readonly property real uiScale: Math.max(0.6, Math.min(2, Plasmoid.configuration.expandedScale / 100))
    readonly property var notificationBackend: notifications
    readonly property var activityBackend: activities
    property bool opened: false
    property bool keyboardRequested: false
    property bool popupReady: false
    property bool geometryLocked: false
    property point popupAnchorPoint: Qt.point(0, 0)
    property real popupAnchorWidth: 240
    property real popupAnchorHeight: 42
    readonly property int configuredHeight: Plasmoid.configuration.compactHeight
    readonly property bool configuredAutoHeight: Plasmoid.configuration.autoHeight
    onConfiguredAutoHeightChanged: close()
    onConfiguredHeightChanged: close()
    onCompactScaleChanged: close()
    property bool interactionHeld: false
    property bool compactHovered: false
    property bool fullHovered: false
    property Item anchorItem: null
    property int selectedPage: 0
    readonly property var savedShelf: Shelf.decode(Plasmoid.configuration.shelfJson)
    readonly property bool wantOpen: opened || notifications.preview !== null
    readonly property string mode: Activity.resolve(Plasmoid.configuration.pinnedMode || "auto", notifications.preview !== null,
        activities.packages.active, systemBackend.playing, activities.llm.active)
    readonly property color accentColor: ({notifications: "#f6c177", packages: "#7ac7ff", media: "#b9a3ff", llm: "#a7e7b8", system: "#89dceb", clock: "#77798d"})[mode] || "#b9a3ff"
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    readonly property string displayText: {
        if (mode === "notifications") return notifications.preview ? notifications.preview.summary : strings.text("Notifications") + " · " + notifications.count;
        if (mode === "media") return systemBackend.title || strings.text("Nothing playing");
        if (mode === "packages") return activities.packages.active ? activities.packages.tool + " · " + activities.packages.operation + " " + (activities.packages.package || "") : strings.text("No package operations detected");
        if (mode === "llm") {
            if (!activities.llm.active) return strings.text("No local models detected");
            const speed = activities.llm.tokens_per_second;
            return activities.llm.model + (speed !== undefined && speed !== null ? " · " + Number(speed).toFixed(1) + " tok/s" : "");
        }
        if (mode === "system") return "CPU " + (activities.system.cpu === undefined || activities.system.cpu === null ? "—" : activities.system.cpu + "%") + " · RAM " + (activities.system.ram === undefined ? "—" : activities.system.ram + "%");
        return clockText;
    }
    Translations { id: strings; language: root.language }
    SystemBackend { id: systemBackend }
    NotificationBackend {
        id: notifications
        previewDuration: Plasmoid.configuration.notificationDuration * 1000
        previewsEnabled: Plasmoid.configuration.notificationPreviews
    }
    ActivityBackend {
        id: activities
        systemEnabled: Plasmoid.configuration.monitorSystem
        packagesEnabled: Plasmoid.configuration.monitorPackages
        llmEnabled: Plasmoid.configuration.monitorLlm
        audioEnabled: Plasmoid.configuration.showAudioDevice
    }
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    activationTogglesExpanded: false
    toolTipMainText: "Boring Island"
    toolTipSubText: displayText
    onExpandedChanged: if (expanded) { expanded = false; open(true); }
    function open(keyboard = false) {
        keyboardRequested = keyboard;
        if (!opened) selectedPage = Activity.page(mode);
        opened = true;
        if (keyboard) Qt.callLater(() => { attachedDialog.requestActivate(); popupShell.forceActiveFocus(); });
    }
    function close() { opened = false; if (notifications) notifications.hidePreviews(); }
    function hoverChanged(compact, hovered) {
        if (compact) compactHovered = hovered; else fullHovered = hovered;
        if (hovered) { closeTimer.stop(); if (!opened && Plasmoid.configuration.hoverOpen) openTimer.restart(); }
        else { openTimer.stop(); closeTimer.restart(); }
    }
    function storeShelf(urls) { Plasmoid.configuration.shelfJson = JSON.stringify(urls); }
    function prepareDialog() {
        if (!anchorItem) return;
        const visual = anchorItem.visualItem;
        popupAnchorPoint = visual.mapToGlobal(0, 0);
        popupAnchorWidth = visual.width;
        popupAnchorHeight = visual.height;
        geometryLocked = true;
        positionDialog();
    }
    function positionDialog() {
        if (!anchorItem) return;
        const point = geometryLocked ? popupAnchorPoint : anchorItem.visualItem.mapToGlobal(0, 0);
        const screen = anchorItem.Window.window ? anchorItem.Window.window.screen : attachedDialog.screen;
        const left = screen ? screen.virtualX : 0;
        const top = screen ? screen.virtualY : 0;
        const right = left + (screen ? screen.width : 1920);
        const bottom = top + (screen ? screen.height : 1080);
        popupShell.maximumHeight = Plasmoid.location === PlasmaCore.Types.BottomEdge ? point.y + popupAnchorHeight - top : bottom - point.y;
        attachedDialog.x = Math.round(Math.max(left, Math.min(right - popupShell.width, point.x + popupAnchorWidth / 2 - popupShell.width / 2)));
        const y = Plasmoid.location === PlasmaCore.Types.BottomEdge ? point.y + popupAnchorHeight - popupShell.height : point.y;
        attachedDialog.y = Math.round(Math.max(top, Math.min(bottom - popupShell.height, y)));
    }
    Timer { id: openTimer; interval: Math.max(100, Plasmoid.configuration.hoverDelay); onTriggered: root.open() }
    Timer { id: closeTimer; interval: 500; onTriggered: if (!root.interactionHeld && !root.compactHovered && !root.fullHovered) root.opened = false }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.clockText = Qt.formatTime(new Date(), "hh:mm") }
    compactRepresentation: CompactView {
        id: compact
        Component.onCompleted: root.anchorItem = compact
        opacity: attachedDialog.visible ? 0 : 1
        language: root.language; backend: systemBackend; notch: root.notch
        displayText: root.displayText; accentColor: root.accentColor
        animateMedia: true; reduceMotion: root.reduceMotion
        compactScale: root.compactScale
        autoHeight: Plasmoid.configuration.autoHeight; compactHeight: Plasmoid.configuration.compactHeight
        showBattery: Plasmoid.configuration.showBattery
        Layout.minimumWidth: 80
        Layout.preferredWidth: root.geometryLocked ? root.popupAnchorWidth : Math.max(80,
            (Plasmoid.configuration.autoWidth ? Math.min(Plasmoid.configuration.compactWidth, naturalWidth) : Plasmoid.configuration.compactWidth) * root.compactScale)
        Layout.fillHeight: true
        Layout.minimumHeight: 16
        Behavior on Layout.preferredWidth { NumberAnimation { duration: root.reduceMotion ? 0 : 260; easing.type: Easing.InOutCubic } }
        onActivated: root.opened ? root.close() : root.open()
        onKeyboardActivated: root.open(true)
        onHoverChanged: hovered => root.hoverChanged(true, hovered)
        onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.selectedPage = 1; root.opened = true; }
    }
    AttachedDialog {
        id: attachedDialog
        visible: root.inPanel && root.anchorItem !== null && root.anchorItem.width > 0 && root.anchorItem.height > 0 && (root.wantOpen || popupShell.progress > 0.001)
        transientParent: root.anchorItem ? root.anchorItem.Window.window : null
        keyboardRequested: root.keyboardRequested
        onWindowDeactivated: root.close()
        onVisibleChanged: {
            root.compactHovered = false;
            root.fullHovered = false;
            if (visible) {
                root.prepareDialog();
                root.popupReady = true;
            } else {
                root.popupReady = false;
                root.geometryLocked = false;
                root.keyboardRequested = false;
            }
        }
        mainItem: ExpandingIsland {
            id: popupShell
            fixedViewport: true
            onWidthChanged: root.positionDialog()
            onHeightChanged: root.positionDialog()
            backend: systemBackend; notifications: root.notificationBackend; activities: root.activityBackend
            opened: root.inPanel && root.popupReady && root.wantOpen; fullView: root.opened
            language: root.language; displayText: root.displayText; accentColor: root.accentColor
            notch: root.notch; bottomEdge: Plasmoid.location === PlasmaCore.Types.BottomEdge
            reduceMotion: root.reduceMotion; uiScale: root.uiScale
            maximumWidth: root.anchorItem && root.anchorItem.Window.window ? root.anchorItem.Window.window.screen.width : 4096
            compactWidth: root.geometryLocked ? root.popupAnchorWidth : (root.anchorItem ? root.anchorItem.width : Plasmoid.configuration.compactWidth)
            compactHeight: root.geometryLocked ? root.popupAnchorHeight : (root.anchorItem ? root.anchorItem.effectiveHeight : 42)
            expandedWidth: Plasmoid.configuration.expandedWidth; expandedHeight: Plasmoid.configuration.expandedHeight
            shelf: root.savedShelf; showBattery: Plasmoid.configuration.showBattery
            pinnedMode: Plasmoid.configuration.pinnedMode; initialPage: root.selectedPage

            onCloseRequested: root.close()
            onActivated: root.opened ? root.close() : root.open()
            onHoverChanged: hovered => root.hoverChanged(false, hovered)
            onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.selectedPage = 1; root.opened = true; }
            onShelfEdited: urls => root.storeShelf(urls)
            onInteractionHeldChangedByUser: held => root.interactionHeld = held
            onPinRequested: mode => Plasmoid.configuration.pinnedMode = mode
        }
    }
    Connections {
        target: root.anchorItem ? root.anchorItem.Window.window : null
        function onXChanged() { if (attachedDialog.visible) root.prepareDialog(); }
        function onYChanged() { if (attachedDialog.visible) root.prepareDialog(); }
        function onScreenChanged() { if (attachedDialog.visible) root.prepareDialog(); }
    }
    fullRepresentation: Item {
        implicitWidth: desktopShell.width; implicitHeight: desktopShell.height
        Layout.minimumWidth: Plasmoid.configuration.compactWidth * root.compactScale
        Layout.minimumHeight: Plasmoid.configuration.autoHeight ? 42 : Plasmoid.configuration.compactHeight
        ExpandingIsland {
            id: desktopShell
            backend: systemBackend; notifications: root.notificationBackend; activities: root.activityBackend
            opened: !root.inPanel && root.wantOpen; fullView: root.opened
            language: root.language; displayText: root.displayText; accentColor: root.accentColor
            notch: root.notch; reduceMotion: root.reduceMotion; uiScale: root.uiScale
            compactWidth: Plasmoid.configuration.compactWidth * root.compactScale
            compactHeight: (Plasmoid.configuration.autoHeight ? 42 : Plasmoid.configuration.compactHeight) * root.compactScale
            expandedWidth: Plasmoid.configuration.expandedWidth; expandedHeight: Plasmoid.configuration.expandedHeight
            shelf: root.savedShelf; showBattery: Plasmoid.configuration.showBattery
            pinnedMode: Plasmoid.configuration.pinnedMode; initialPage: root.selectedPage
            onCloseRequested: root.close()
            onActivated: root.opened ? root.close() : root.open()
            onHoverChanged: hovered => root.hoverChanged(false, hovered)
            onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.selectedPage = 1; root.opened = true; }
            onShelfEdited: urls => root.storeShelf(urls)
            onInteractionHeldChangedByUser: held => root.interactionHeld = held
            onPinRequested: mode => Plasmoid.configuration.pinnedMode = mode
        }
    }
}
