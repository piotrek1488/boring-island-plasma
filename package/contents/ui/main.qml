pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../code/Shelf.js" as Shelf
import "../code/Activity.js" as Activity
import "../code/Sizing.js" as Sizing

PlasmoidItem {
    id: root
    readonly property string language: Plasmoid.configuration.language || "en"
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool editing: Plasmoid.userConfiguring || (Plasmoid.containment !== null
        && (Plasmoid.containment.userConfiguring || (Plasmoid.containment.corona !== null && Plasmoid.containment.corona.editMode)))
    onEditingChanged: if (editing) {
        if (openTimer) openTimer.stop();
        if (closeTimer) closeTimer.stop();
        compactHovered = false; fullHovered = false; interactionHeld = false;
        close();
    }
    readonly property bool notch: Plasmoid.configuration.shape === 0
    readonly property string animationStyle: Plasmoid.configuration.animationStyle === "spring" ? "spring" : "smooth"
    readonly property int animationDuration: Math.max(50, Math.min(1000, Plasmoid.configuration.animationDuration))
    readonly property var configureAction: Plasmoid.internalAction("configure")
    readonly property bool configureEnabled: configureAction !== null && configureAction.enabled
    function configure() { close(); if (configureAction && configureAction.enabled) configureAction.trigger(); }
    readonly property bool reduceMotion: Plasmoid.configuration.reduceMotion
    readonly property real compactScale: Math.max(0.5, Math.min(2, Plasmoid.configuration.compactScale / 100))
    readonly property real uiScale: Math.max(0.6, Math.min(2, Plasmoid.configuration.expandedScale / 100))
    readonly property var notificationBackend: notifications
    readonly property var activityBackend: activities
    property bool opened: false
    property bool focusRequested: false
    property bool popupReady: false
    property bool geometryLocked: false
    property point popupAnchorPoint: Qt.point(0, 0)
    property real popupAnchorWidth: 240
    property real popupAnchorHeight: 42
    property rect popupScreenGeometry: Qt.rect(0, 0, 1920, 1080)
    property real popupMaximumHeight: 1080
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
    readonly property bool wantOpen: !editing && (opened || (!osdState.active && (notifications.preview !== null || lowBattery.active)))
    readonly property string baseMode: Activity.resolve(Plasmoid.configuration.pinnedMode || "auto", false,
        activities.packages.active, systemBackend.playing, activities.llm.active, savedShelf.length, notifications.count)
    readonly property string mode: osdState.active ? "osd" : notifications.preview !== null ? "notifications" : baseMode
    readonly property bool compactBatteryOnly: mode === "clock" && !lowBattery.active && Plasmoid.configuration.idleView === "battery" && Plasmoid.configuration.showBattery && systemBackend.hasBattery
    readonly property string mediaTimeText: Activity.timeLabel(systemBackend.position) + " / " + (systemBackend.duration > 0 ? Activity.timeLabel(systemBackend.duration) : "—")
    readonly property color accentColor: ({notifications: "#f6c177", packages: "#7ac7ff", media: "#b9a3ff", llm: "#a7e7b8", system: "#89dceb", clock: "#77798d"})[mode] || "#b9a3ff"
    property date currentTime: new Date()
    readonly property string clockText: Qt.formatTime(currentTime, "hh:mm")
    readonly property string displayText: {
        if (mode === "osd") return osdState.current.kind === "brightness" ? strings.text("Brightness") : strings.text("Volume");
        if (lowBattery.active) return strings.text("Low battery") + " · " + systemBackend.percent + "%";
        if (mode === "notifications") return notifications.preview ? notifications.preview.summary : strings.text("Notifications") + " · " + notifications.count;
        if (mode === "media") return systemBackend.title || strings.text("Nothing playing");
        if (mode === "shelf") return strings.text("Shelf") + " · " + savedShelf.length;
        if (mode === "packages") return activities.packages.active ? activities.packages.tool + " · " + activities.packages.operation + " " + (activities.packages.package || "") : strings.text("No package operations detected");
        if (mode === "llm") {
            if (!activities.llm.active) return strings.text("No local models detected");
            const speed = activities.llm.tokens_per_second;
            return activities.llm.model + (speed !== undefined && speed !== null ? " · " + Number(speed).toFixed(1) + " tok/s" : "");
        }
        if (mode === "system") return "CPU " + (activities.system.cpu === undefined || activities.system.cpu === null ? "—" : activities.system.cpu + "%") + " · RAM " + (activities.system.ram === undefined ? "—" : activities.system.ram + "%");
        return Activity.idleText(Plasmoid.configuration.idleView, currentTime, strings.locale);
    }
    Translations { id: strings; language: root.language }
    SystemBackend { id: systemBackend }
    OsdState { id: osdState; enabled: Plasmoid.configuration.showOsd && !root.editing; duration: Plasmoid.configuration.osdDuration * 1000 }
    NativeServices {
        id: nativeServices
        language: root.language
        onReminderActivated: { root.open(true); root.selectedPage=3; }
        osdEnabled: osdState.enabled
        onProgressReceived: (icon,value,maximum,description) => osdState.progress(icon,value,maximum,description)
        onTextReceived: (icon,description) => osdState.text(icon,description)
        onDelivered: (key,notificationId) => reminderScheduler.acknowledge(key)
    }
    ReminderCalendar {
        id: reminderCalendar
        enabled: Plasmoid.configuration.remindersEnabled
        mode: Plasmoid.configuration.calendarMode; sources: Plasmoid.configuration.calendarSources; appletId: Plasmoid.id
    }
    ReminderScheduler {
        id: reminderScheduler
        enabled: Plasmoid.configuration.remindersEnabled
        events: reminderCalendar.events
        leadMinutes: Plasmoid.configuration.reminderLeadMinutes
        stateJson: Plasmoid.configuration.reminderStateJson
        onStateEdited: json => Plasmoid.configuration.reminderStateJson = json
        onReminder: (event,phase,key) => nativeServices.notify(key,
            (phase === "start" ? strings.text("Event starting now") : strings.text("Upcoming event")) + " · " + event.title,
            event.title + " — " + Qt.formatTime(new Date(event.startDateTime), "hh:mm"))
    }
    LowBatteryMonitor {
        id: lowBattery
        suspended: osdState.active
        hasBattery: systemBackend.hasBattery
        percent: systemBackend.percent
        powered: systemBackend.powerConnected
        duration: Plasmoid.configuration.notificationDuration * 1000
    }
    readonly property string batteryWarning: lowBattery.active ? strings.text("Low battery") + " · " + systemBackend.percent + "% — " + strings.text("Connect the charger.") : ""
    NotificationBackend {
        id: notifications
        previewsSuspended: osdState.active || lowBattery.active
        previewDuration: Plasmoid.configuration.notificationDuration * 1000
        previewsEnabled: !root.editing && Plasmoid.configuration.notificationPreviews
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
        if (editing) return;
        if (!opened) focusRequested = keyboard;
        else if (keyboard) focusRequested = true;
        if (!opened) selectedPage = Activity.page(mode === "osd" ? baseMode : mode);
        opened = true;
        if (keyboard) {
            activateFromInteraction();
            Qt.callLater(() => { if (root.focusRequested && attachedDialog.visible) popupShell.forceActiveFocus(); });
        }
    }
    function activateFromInteraction() {
        if (editing || !inPanel || !wantOpen) return;
        // Let the original control handle this pointer event before activation.
        Qt.callLater(() => {
            if (root.editing || !root.wantOpen || !attachedDialog.visible) return;
            root.focusRequested = true;
            attachedDialog.requestActivate();
        });
    }
    function close() { if (lowBattery) lowBattery.dismiss(); opened = false; if (notifications) notifications.hidePreviews(); }
    function hoverChanged(compact, hovered) {
        if (editing) return;
        if (compact) compactHovered = hovered; else fullHovered = hovered;
        if (hovered) { closeTimer.stop(); if (!opened && Plasmoid.configuration.hoverOpen) openTimer.restart(); }
        else { openTimer.stop(); closeTimer.restart(); }
    }
    function storeShelf(urls) { Plasmoid.configuration.shelfJson = JSON.stringify(urls); }
    function prepareDialog() {
        if (!anchorItem) return;
        const visual = anchorItem.visualItem;
        if (!visual) return;
        // Native Plasma windows expose their screen to items through Screen;
        // Window.window.screen is only available on the QML Window wrapper.
        const screen = visual.Screen;
        // During display hotplug/dock changes KWin can momentarily report no
        // outputs ("There are no outputs - creating placeholder screen"). The
        // attached Screen then has no backing QScreen and reading its geometry
        // fields dereferences null, crashing plasmashell. Skip this pass and
        // wait for the next screenChanged once a real output is back.
        if (!screen || screen.width <= 0 || screen.height <= 0) return;
        popupAnchorPoint = visual.mapToGlobal(0, 0);
        popupAnchorWidth = visual.width;
        popupAnchorHeight = visual.height;
        popupScreenGeometry = Qt.rect(screen.virtualX, screen.virtualY, screen.width, screen.height);
        popupMaximumHeight = Math.max(1, Plasmoid.location === PlasmaCore.Types.BottomEdge
            ? popupAnchorPoint.y + popupAnchorHeight - popupScreenGeometry.y
            : popupScreenGeometry.y + popupScreenGeometry.height - popupAnchorPoint.y);
        geometryLocked = true;
        positionDialog();
    }
    function positionDialog() {
        if (!anchorItem || !geometryLocked) return;
        const point = popupAnchorPoint;
        const left = popupScreenGeometry.x;
        const top = popupScreenGeometry.y;
        const right = left + popupScreenGeometry.width;
        const bottom = top + popupScreenGeometry.height;
        attachedDialog.x = Math.round(Math.max(left, Math.min(right - popupShell.width, point.x + popupAnchorWidth / 2 - popupShell.width / 2)));
        const y = Plasmoid.location === PlasmaCore.Types.BottomEdge ? point.y + popupAnchorHeight - popupShell.height : point.y;
        attachedDialog.y = Math.round(Math.max(top, Math.min(bottom - popupShell.height, y)));
    }
    Timer { id: openTimer; interval: Math.max(100, Plasmoid.configuration.hoverDelay); onTriggered: root.open() }
    Timer { id: closeTimer; interval: 30; onTriggered: if (!root.interactionHeld && !root.compactHovered && !root.fullHovered && root.opened) root.close() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.currentTime = new Date() }
    compactRepresentation: CompactView {
        id: compact
        enabled: !root.editing
        panelItem: !root.editing && root.inPanel && compact.Window.window ? compact.Window.window.contentItem : null
        Component.onCompleted: root.anchorItem = compact
        opacity: attachedDialog.visible ? 0 : 1
        language: root.language; backend: systemBackend; notch: root.notch
        displayText: root.displayText; accentColor: root.accentColor
        alternateText: root.mediaTimeText; cycleText: root.mode === "media" && systemBackend.playing && !lowBattery.active
        cycleInterval: Plasmoid.configuration.mediaCycleSeconds * 1000
        batteryOnly: root.compactBatteryOnly; osd: osdState.current
        batteryPercentPosition: Plasmoid.configuration.batteryPercentPosition
        configureEnabled: root.configureEnabled
        onConfigureRequested: root.configure()
        animateMedia: true; reduceMotion: root.reduceMotion
        compactScale: root.compactScale
        autoHeight: Plasmoid.configuration.autoHeight; compactHeight: Plasmoid.configuration.compactHeight
        showBattery: Plasmoid.configuration.showBattery
        Layout.minimumWidth: 80
        Layout.preferredWidth: root.geometryLocked ? root.popupAnchorWidth : Sizing.compactWidth(Plasmoid.configuration.autoWidth, Plasmoid.configuration.compactMinimumWidth, Plasmoid.configuration.compactWidth, naturalWidth, root.compactScale)
        Layout.fillHeight: true
        Layout.minimumHeight: 16
        Behavior on Layout.preferredWidth { NumberAnimation { duration: root.reduceMotion ? 0 : root.animationDuration; easing.type: Easing.InOutCubic } }
        onActivated: root.opened ? root.close() : root.open(true)
        onKeyboardActivated: root.open(true)
        onHoverChanged: hovered => root.hoverChanged(true, hovered)
        onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.selectedPage = 1; root.opened = true; }
    }
    AttachedDialog {
        id: attachedDialog
        visible: !root.editing && root.inPanel && root.anchorItem !== null && root.anchorItem.width > 0 && root.anchorItem.height > 0 && (root.wantOpen || popupShell.progress > 0.001)
        transientParent: root.anchorItem ? root.anchorItem.Window.window : null
        focusRequested: root.focusRequested
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
                root.focusRequested = false;
            }
        }
        mainItem: ExpandingIsland {
            id: popupShell
            calendarMode: Plasmoid.configuration.calendarMode
            calendarSources: Plasmoid.configuration.calendarSources
            calendarAppletId: Plasmoid.id
            editing: root.editing
            fixedViewport: true
            // Dialog synchronizes its native size in these same signals. Move
            // after that update, and never feed the new size back into its limit.
            onWidthChanged: Qt.callLater(root.positionDialog)
            onHeightChanged: Qt.callLater(root.positionDialog)
            backend: systemBackend; notifications: root.notificationBackend; activities: root.activityBackend
            opened: root.inPanel && root.popupReady && root.wantOpen; fullView: root.opened
            language: root.language; displayText: root.displayText; accentColor: root.accentColor
            notch: root.notch; bottomEdge: Plasmoid.location === PlasmaCore.Types.BottomEdge
            batteryWarning: root.batteryWarning
            compactAlternateText: root.mediaTimeText
            compactCycleText: root.mode === "media" && systemBackend.playing && !lowBattery.active
            compactCycleInterval: Plasmoid.configuration.mediaCycleSeconds * 1000
            compactBatteryOnly: root.compactBatteryOnly; osd: osdState.current
            animationStyle: root.animationStyle
            animationDuration: root.animationDuration
            batteryPercentPosition: Plasmoid.configuration.batteryPercentPosition
            configureEnabled: root.configureEnabled
            onConfigureRequested: root.configure()
            onInteractionRequested: root.activateFromInteraction()
            reduceMotion: root.reduceMotion; uiScale: root.uiScale
            maximumWidth: root.popupScreenGeometry.width
            maximumHeight: root.popupMaximumHeight
            compactWidth: root.geometryLocked ? root.popupAnchorWidth : (root.anchorItem ? root.anchorItem.width : Plasmoid.configuration.compactWidth)
            compactHeight: root.geometryLocked ? root.popupAnchorHeight : (root.anchorItem ? root.anchorItem.effectiveHeight : 42)
            expandedWidth: Plasmoid.configuration.expandedWidth; expandedHeight: Plasmoid.configuration.expandedHeight
            shelf: root.savedShelf; showBattery: Plasmoid.configuration.showBattery
            pinnedMode: Plasmoid.configuration.pinnedMode; initialPage: root.selectedPage

            onCloseRequested: root.close()
            onActivated: root.opened ? root.close() : root.open(true)
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
            calendarMode: Plasmoid.configuration.calendarMode
            calendarSources: Plasmoid.configuration.calendarSources
            calendarAppletId: Plasmoid.id
            editing: root.editing
            backend: systemBackend; notifications: root.notificationBackend; activities: root.activityBackend
            opened: !root.inPanel && root.wantOpen; fullView: root.opened
            language: root.language; displayText: root.displayText; accentColor: root.accentColor
            batteryWarning: root.batteryWarning
            compactAlternateText: root.mediaTimeText
            compactCycleText: root.mode === "media" && systemBackend.playing && !lowBattery.active
            compactCycleInterval: Plasmoid.configuration.mediaCycleSeconds * 1000
            compactBatteryOnly: root.compactBatteryOnly; osd: osdState.current
            animationStyle: root.animationStyle
            animationDuration: root.animationDuration
            batteryPercentPosition: Plasmoid.configuration.batteryPercentPosition
            configureEnabled: root.configureEnabled
            onConfigureRequested: root.configure()
            onInteractionRequested: root.activateFromInteraction()
            notch: root.notch; reduceMotion: root.reduceMotion; uiScale: root.uiScale
            compactWidth: Plasmoid.configuration.compactWidth * root.compactScale
            compactHeight: (Plasmoid.configuration.autoHeight ? 42 : Plasmoid.configuration.compactHeight) * root.compactScale
            expandedWidth: Plasmoid.configuration.expandedWidth; expandedHeight: Plasmoid.configuration.expandedHeight
            shelf: root.savedShelf; showBattery: Plasmoid.configuration.showBattery
            pinnedMode: Plasmoid.configuration.pinnedMode; initialPage: root.selectedPage
            onCloseRequested: root.close()
            onActivated: root.opened ? root.close() : root.open(true)
            onHoverChanged: hovered => root.hoverChanged(false, hovered)
            onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.selectedPage = 1; root.opened = true; }
            onShelfEdited: urls => root.storeShelf(urls)
            onInteractionHeldChangedByUser: held => root.interactionHeld = held
            onPinRequested: mode => Plasmoid.configuration.pinnedMode = mode
        }
    }
}
